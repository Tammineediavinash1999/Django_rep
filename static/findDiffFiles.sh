#!/bin/bash


# ********************************************************************************************
# This program will find difference in file pattern in given folder of the ${SERVER_CONTEXT} ZIP between ${SOURCE_VERSION} and ${TARGET_VERSION} version as available in artifactory
# ********************************************************************************************


BOLD='\033[1m'
readonly strTEMP=TEMP
readonly strADMIN=ADMIN
readonly strJOB=JOB
readonly strCA=CA
readonly strResources=resources
readonly strResourceTypes=resource-types
readonly strSchemas=schemas
readonly strMetaInf=META-INF

helpProgram()
{
	echo ""
	echo "********************************************************************************************"
	echo "This program will find difference in file pattern in ${FOLDER} folder of the ${SERVER_CONTEXT} ZIP between ${SOURCE_VERSION} and ${TARGET_VERSION} version as available in artifactory"
	echo "Currently it is running for ${SERVER_CONTEXT} with Source IDCS Build Version ${SOURCE_VERSION}, Target IDCS Build Version ${TARGET_VERSION} and file pattern ${FILE_PATTERN} in ${FOLDER} folder"
        echo "********************************************************************************************"
	echo ""
}

findDiff()
{
	local SOURCE_DIR_TEMP=${SOURCE_DIR}"/"${strTEMP}"/"${FOLDER}
	local TARGET_DIR_TEMP=${TARGET_DIR}"/"${strTEMP}"/"${FOLDER}
	#for i in `find ${SOURCE_DIR_TEMP} -name ${FILE_PATTERN} | grep -v "schema" | grep -v "resource-types"`
	if [[ ${FOLDER} == ${strResources} ]];then
		local excludeDir1=${strResourceTypes}
		local excludeDir2=${strSchemas}
	elif [[ ${FOLDER} == ${strResourceTypes} ]];then
                local excludeDir1=${strResources}
                local excludeDir2=${strSchemas}
	elif [[ ${FOLDER} == ${strSchemas} ]];then
                local excludeDir1=${strResources}
                local excludeDir2=${strResourceTypes}
	fi
	#for i in `find ${SOURCE_DIR_TEMP} -name ${FILE_PATTERN} | grep -v ${excludeDir1} | grep -v ${excludeDir2}`
	for i in `find ${SOURCE_DIR_TEMP} -name ${FILE_PATTERN} -not \( -path "*\/${excludeDir1}\/*" -prune \) -not \( -path "*\/${excludeDir2}\/*" -prune \)`
	do
		local SOURCE_FILE=$i
		if [[ "${SOURCE_FILE}" == *"${strMetaInf}"* ]];then
			local RESOURCE_TYPE=`echo $i | cut -d "/" -f 8 | cut -d "-" -f 1`
			#local JSON_FILE=`echo $i | cut -d "/" -f 12`
			local JSON_FILE=`echo $i | rev | cut -d "/" -f 1 | rev`
			local TARGET_PATH="${SOURCE_FILE//$SOURCE_VERSION/$TARGET_VERSION}"
			local ATRGET_FILE=""
			TARGET_FILE=`find ${TARGET_PATH} -name "$JSON_FILE"`
			if [[ ! -z ${TARGET_FILE} ]];then
				DIFF_CNT=`diff $SOURCE_FILE $TARGET_FILE | wc -l`
				if [[ $DIFF_CNT -gt 0 ]];then
					echo ""
					echo "**********************************"
					echo "MODIFIED JSON FILE"
					echo "JSON_FILE=$JSON_FILE"
					echo "DIFF_CNT=$DIFF_CNT"
					echo "SOURCE_FILE=$SOURCE_FILE"
					echo "TARGET_FILE=$TARGET_FILE"
					echo "**********************************"
					echo ""
				fi
			else
				echo ""
				echo "++++++++++++++++++++++++++++++++++"
				echo "NEW JSON FILE ADDED"
				echo "JSON_FILE=$JSON_FILE"
				echo "Found in $SOURCE_DIR but not in $TARGET_DIR"
				echo "SOURCE_FILE=$SOURCE_FILE"
				echo "++++++++++++++++++++++++++++++++++"
				echo ""
			fi
		fi
	done
}

main()
{
	# Print purpose of the program
	helpProgram

	# Current Directory
	CURR_DIR=`pwd`
	echo "INFO: Current Directory is ${CURR_DIR}"

	# Execution Directory
	EXEC_FILE=$(basename "$0")
	EXEC_DIR=$(dirname "$0")
 
 
	# If the shell file is executed from a relative path then replace the (.) with current directory
	EXEC_DIR="${EXEC_DIR/./$CURR_DIR}"
	echo "INFO: Execution Directory is ${EXEC_DIR}"

	# Construct the SOURCE and TARGET folder
	if [[ ${SERVER_CONTEXT} == ${strADMIN} ]];then
		local SRC_SERVER_DIR=admin-srv-all-${SOURCE_VERSION}
		local TGT_SERVER_DIR=admin-srv-all-${TARGET_VERSION}
	elif [[ ${SERVER_CONTEXT} == ${strJOB} ]];then
		local SRC_SERVER_DIR=job-srv-all-${SOURCE_VERSION}
		local TGT_SERVER_DIR=job-srv-all-${TARGET_VERSION}
	elif [[ ${SERVER_CONTEXT} == ${strCA} ]];then
		local SRC_SERVER_DIR=ca-srv-all-${SOURCE_VERSION}
		local TGT_SERVER_DIR=ca-srv-all-${TARGET_VERSION}
	fi

	
	SOURCE_DIR=${EXEC_DIR}/${SRC_SERVER_DIR}
	TARGET_DIR=${EXEC_DIR}/${TGT_SERVER_DIR}

	# Find the difference (if any)		
	findDiff
}


# Clear the console
clear

# Take the Input Parameters
while [[ $# -gt 0 ]]; do
	opt="$1"
	shift;
	current_arg="$1"
	if [[ "$current_arg" =~ ^-{1,2}.* ]]; then
		echo "WARNING: You may have left an argument blank. Double check your command."
	fi
	case "$opt" in
		"-sv"|"--sourcever"     ) SOURCE_VERSION=$1; shift;;
		"-tv"|"--targetver"    	) TARGET_VERSION=$1; shift;;
		"-fp"|"--filepattern"	) FILE_PATTERN=$1; shift;;
		"-s"|"--server"       	) SERVER_CONTEXT=$( tr '[:lower:]' '[:upper:]' <<<"$1" ); shift;;
		"-f"|"--folder"       	) FOLDER=$( tr '[:upper:]' '[:lower:]' <<<"$1" ); shift;;
		*                       ) echo "ERROR: Invalid option: \""${opt}"\". Exiting..."
		exit 1;;
	esac
done

if [[ -z ${SOURCE_VERSION} || -z ${FILE_PATTERN} || -z ${TARGET_VERSION} || -z ${SERVER_CONTEXT} || -z ${FOLDER} ]]; then
	echo ""
	echo "INFO: This program finds difference in file pattern in RESOURCE folder of all JARS in the provided context between IDCS source and target build version"
	echo "INFO: This program needs four parameters"
	echo "INFO: -sv|--sourcever ===> source version"
	echo "INFO: -tv|--targetver ===> target version"
	echo "INFO: -s|--server ===> server context"
	echo "INFO: -fp|--filepattern ===> File / File Pattern to be checked"
	echo "INFO: -f|--folder ===> Folder in which File / File Pattern to be checked"
	echo "WARNING: No/all required parameter(s) is/are provided"
	echo "INFO: Provided Parameters: (i) -sv|--sourcever ===> ${SOURCE_VERSION}, (ii) -fp|--filepattern ===> ${FILE_PATTERN}, (iii) -tv|--targetver ===> ${TARGET_VERSION}, (iv) -s|--server ===> ${SERVER_CONTEXT}, (v) -f|--folder ===> ${FOLDER}"
	echo "ERROR: Exiting..."
	echo ""
	exit 1
fi


# Validate SERVER_CONTEXT flag value
case "${SERVER_CONTEXT}" in
	"${strADMIN}"	) echo "";;
	"${strJOB}"	) echo "";;
	"${strCA}"	) echo "";;
	*		) echo "ERROR: Invalid value of parameter ["-s"|"--server"]="${SERVER_CONTEXT}". Valid values are ${strADMIN} or ${strJOB} or ${strCA}. Exiting..."
	exit 1;;
esac


# Call MAIN function
main
