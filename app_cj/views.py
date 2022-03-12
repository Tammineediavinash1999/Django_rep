from django.shortcuts import render
import os
import json
import subprocess
 


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
STATIC_ROOT = os.path.join(BASE_DIR, 'static')

CONFIG_FILE = os.path.join(STATIC_ROOT,'tem_idcs.config')
EXECUTABLE_FILE = os.path.join(STATIC_ROOT,'diffJob')
LOG_FILE = os.path.join(STATIC_ROOT,'diff.log')
# Create your views here.
def index(request):
    return render(request, "app_cj/mainpage.html")


def submit(request):
    if request.method == 'POST':
        build_no = request.POST['inputBuild']

        with open(CONFIG_FILE) as json_file:
            data = json.load(json_file)

        data['diff']['config']['source']['customBuild'] = build_no

        with open(CONFIG_FILE,'w') as json_file:
            json.dump(data, json_file)

        proc = subprocess.Popen([EXECUTABLE_FILE , CONFIG_FILE, '>&',LOG_FILE])
        print("PID:", proc.pid)
        print("Return code:", proc.wait())
        

        
