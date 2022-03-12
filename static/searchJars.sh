  #!/bin/bash

# ********************************************************************************************
# This program will download the server context JAR for a given version available in artifactory
# Then it will check the existence of JSON file in given folder in the existing JARS
# If found, it will copy the JARS in specific TEMP folder (FOLDER/JAR_NAME appended with TEMP string) under TEMP path of the provided source folder
# Each JAR will be exploded in the JAR_NAME appended with TEMP string
# For example, if JSON has been found in abc-16.3.6-rel.797.jar, then 
# it will be copied into TEMP/abc-16.3.6-rel.797_TEMP folder
# then it will be exploded in TEMP/abc-16.3.6-rel.797_TEMP folder
# ********************************************************************************************

readonly strTEMP=TEMP
readonly strADMIN=ADMIN
readonly strJOB=JOB
readonly strCA=CA
readonly strSSO=SSO
ARTIFACTORY_LOCATION="http://artifactory-slc.oraclecorp.com/artifactory/idcs-virtual"

helpProgram()
{
	echo ""
	echo "********************************************************************************************"
	echo "This program will download the ${SERVER_CONTEXT} ZIP for a ${BUILD_VERSION} version as available in artifactory"
        echo "Then it will check the (case sensitive) existence of the file/file pattern in ${FOLDER} folder in the existing JARS"
        echo "If found, it will copy the JARS in specific TEMP folder (${FOLDER}/JAR_NAME appended with TEMP string) under TEMP path of the provided source folder"
        echo "Each JAR will be exploded in the JAR_NAME appended with TEMP string"
        echo "For example, if JSON has been found in abc-16.3.6-rel.797.jar, then - "
        echo "  a) it will be copied into TEMP/abc-16.3.6-rel.797_TEMP folder"
        echo "  b) then it will be exploded in TEMP/abc-16.3.6-rel.797_TEMP folder"
	echo "Currently it is running for ${SERVER_CONTEXT} with IDCS Build Version ${BUILD_VERSION} with file pattern ${FILE_PATTERN}"
        echo "********************************************************************************************"
	echo ""
}

searchJars()
{
	#for i in `find $SOURCE_DIR -name "*jar"`
	for i in `find $SOURCE_DIR -name "*jar" -not -path "*\/${strTEMP}\/*"`
	do
		jar tvf $i | grep ${FILE_PATTERN} | grep "META-INF\/idaas-resources\/${FOLDER}"> /dev/null
  		if [[ $? == 0 ]];then
			EXEC_DIR_LEVEL=`echo "${EXEC_DIR}" | awk -F'[/]' '{printf NF}'`
			local JAR_POS_ADD=3
			JAR_POS=$(expr "${EXEC_DIR_LEVEL}" + "${JAR_POS_ADD}")
			#JAR_NAME=`echo $i | cut -d "/" -f 8` 
			JAR_NAME=`echo $i | cut -d "/" -f "${JAR_POS}"` 
			JAR_TEMP_DIR=${SOURCE_TEMP}/${JAR_NAME}"_"${strTEMP}
			mkdir -p $JAR_TEMP_DIR
			cp $i $JAR_TEMP_DIR
			pushd $JAR_TEMP_DIR > /dev/null
			jar -xvf $JAR_NAME > /dev/null
			popd > /dev/null
  		fi
	done
}

downloadZip()
{
	if [[ ${SERVER_CONTEXT} == ${strADMIN} ]];then
		local SRV_URL="${ARTIFACTORY_LOCATION}"/oracle/idaas/admin-srv-all/${BUILD_VERSION}/admin-srv-all-${BUILD_VERSION}.zip
		local SERVER_DIR=admin-srv-all-${BUILD_VERSION}
	elif [[ ${SERVER_CONTEXT} == ${strJOB} ]];then
		local SRV_URL="${ARTIFACTORY_LOCATION}"/oracle/idaas/job-srv-all/${BUILD_VERSION}/job-srv-all-${BUILD_VERSION}.zip
		local SERVER_DIR=job-srv-all-${BUILD_VERSION}
	elif [[ ${SERVER_CONTEXT} == ${strCA} ]];then
		local SRV_URL="${ARTIFACTORY_LOCATION}"/oracle/idaas/ca-srv-all/${BUILD_VERSION}/ca-srv-all-${BUILD_VERSION}.zip
		local SERVER_DIR=ca-srv-all-${BUILD_VERSION}
	elif [[ ${SERVER_CONTEXT} == ${strSSO} ]];then
		local SRV_URL="${ARTIFACTORY_LOCATION}"/oracle/idaas/ca-srv-all/${BUILD_VERSION}/sso-srv-all-${BUILD_VERSION}.zip
		local SERVER_DIR=ca-srv-all-${BUILD_VERSION}
	fi
	
	# Created a Source Directory
	SOURCE_DIR=${EXEC_DIR}/${SERVER_DIR}
	
	echo "++++++++++++++++++++++++++++++++++++++++++"
	echo "SOURCE_DIR=${SOURCE_DIR}"
	echo "SRV_URL=${SRV_URL}"
	echo "++++++++++++++++++++++++++++++++++++++++++"

	if [[ ! -f ${SOURCE_DIR}.zip ]];then
		# Download the ZIP file
		curl -o ${SOURCE_DIR}.zip ${SRV_URL}
		if [[ -f ${SOURCE_DIR}.zip ]];then
			# Unzip the downloaded ZIP file
			unzip ${SOURCE_DIR}.zip -d ${EXEC_DIR} > /dev/null
		else
			echo "ERROR: ZIP file ${SOURCE_DIR}.zip is missing. Exiting..."
			exit 1
		fi
	else
		echo "INFO: Already Found ${SOURCE_DIR}.zip, hence not downloading again"
	fi

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


	# Download the ZIP File
	downloadZip
	
	# Variable for TEMP folder
	SOURCE_TEMP=${SOURCE_DIR}/${strTEMP}/${FOLDER}

	if [[ -d $SOURCE_TEMP ]];then
		rm -rf $SOURCE_TEMP
	fi
  
	echo "INFO: Looking existence of ${FILE_PATTERN} in ${FOLDER} folder of ${SOURCE_DIR}......"
	# Call searchJars function to identify, copy and explode JARS which contain JSON file in RESOURCE folder
	searchJars
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
		"-v"|"--buildver"       ) BUILD_VERSION=$1; shift;;
		"-s"|"--server"       	) SERVER_CONTEXT=$( tr '[:lower:]' '[:upper:]' <<<"$1" ); shift;;
		"-fp"|"--filepattern"	) FILE_PATTERN=$1; shift;;
		"-f"|"--folder"		) FOLDER=$( tr '[:upper:]' '[:lower:]' <<<"$1" ); shift;;
		"-al"|"--artifactory"	) ARTIFACTORY_LOCATION=$( tr '[:upper:]' '[:lower:]' <<<"$1" ); shift;;
		*                       ) echo "ERROR: Invalid option: \""${opt}"\". Exiting..."
		exit 1;;
	esac
done
 
if [[ -z ${BUILD_VERSION} || -z ${FILE_PATTERN} || -z ${SERVER_CONTEXT} || -z ${FOLDER} ]]; then
	echo ""
	echo "INFO: This program finds file / file pattern in RESOURCE folder of all JARS in the provided context of IDCS build version"
	echo "INFO: This program needs three parameters"
	echo "INFO: -v|--buildver ===> build version"
	echo "INFO: -s|--server ===> server context"
	echo "INFO: -fp|--filepattern ===> File / File Pattern to be searched"
	echo "INFO: -f|--folder ===> Folder where the File / File Pattern to be searched"
	echo "WARNING: No/all required parameter(s) is/are provided"
	echo "INFO: Provided Parameters: (i) -v|--buildver ===> ${BUILD_VERSION}, (ii) -fp|--filepattern ===> ${FILE_PATTERN}, (iii) -s|--server ===> ${SERVER_CONTEXT}, (iv) -f|--folder ===> ${FOLDER}"
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
