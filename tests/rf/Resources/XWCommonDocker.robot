*** Settings ***
Library  Process
Library  OperatingSystem
Library  String
Resource  XWServerDocker.robot
Resource  XWWorkerDocker.robot
Resource  ./DB/MySqlDocker.robot
Resource  ./DockerHelper.robot

*** Variables ***

${RF_RESULT_PATH} =  ../Results
${XW_GIT_URL} =  https://github.com/iExecBlockchainComputing/xtremweb-hep.git
${XW_GIT_BRANCH} =  master
${XW_FORCE_GIT_CLONE} =  false
${XW_PATH} =  ./xtremweb-hep/
${BUILD_PATH} =  ${XW_PATH}/build
${RESOURCES_PATH} =  ${XW_PATH}/src/main/resources
${DIST_PATH} =  ${BUILD_PATH}/dist
${DIST_XWHEP_PATH}
${XTREMWEB_VERSION}
${XW_CACHE_DIR} =  /tmp
${XW_SERVER_NAME} =  localhost
#vagrant-ubuntu-trusty-64


## xwconfigure.values
${XWCONFIGURE.VALUES.XWUSER} =  root
${XWCONFIGURE.VALUES.DBVENDOR} =  MySqlDocker
${XWCONFIGURE.VALUES.DBENGINE} =  InnoDB
${XWCONFIGURE.VALUES.DBHOST} =  db
${XWCONFIGURE.VALUES.DBADMINLOGIN} =  root
${XWCONFIGURE.VALUES.DBADMINPASSWORD} =  root
${XWCONFIGURE.VALUES.DBNAME} =  xtremweb
${XWCONFIGURE.VALUES.DBUSERLOGIN} =  xwuser
${XWCONFIGURE.VALUES.DBUSERPASSWORD} =  xwuser
${XWCONFIGURE.VALUES.XWADMINLOGIN} =  admin
${XWCONFIGURE.VALUES.XWADMINPASSWORD} =  admin
${XWCONFIGURE.VALUES.XWWorkerDockerLOGIN} =  worker
${XWCONFIGURE.VALUES.XWWorkerDockerPASSWORD} =  worker
${XWCONFIGURE.VALUES.XWVWORKERLOGIN} =  vworker
${XWCONFIGURE.VALUES.XWVWORKERPASSWORD} =  vworker
${XWCONFIGURE.VALUES.XWServerDocker} =  ${XW_SERVER_NAME}
${XWCONFIGURE.VALUES.CERTCN} =  ${XW_SERVER_NAME}
${XWCONFIGURE.VALUES.CERTOU} =  MrRobotFramework
${XWCONFIGURE.VALUES.CERTO} =  MrRobotFramework
${XWCONFIGURE.VALUES.CERTL} =  MrRobotFramework
${XWCONFIGURE.VALUES.CERTC} =  fr
${XWCONFIGURE.VALUES.SSLKEYPASSPHRASE} =  MrRobotFramework
${XWCONFIGURE.VALUES.SSLKEYSERVERPASSWORD} =  MrRobotFramework
${XWCONFIGURE.VALUES.SSLTRUSTSTOREPASSWORD} =  changeit
${XWCONFIGURE.VALUES.X509CERTDIR} =  /tmp/castore
${XWCONFIGURE.VALUES.USERCERTDIR} =
${XWCONFIGURE.VALUES.XWUPGRADEURL} =  http://${XW_SERVER_NAME}:8080/somewhere/xtremweb.jar
${XWCONFIGURE.VALUES.HTTPSPORT} =  9443




*** Keywords ***


Prepare XWtremWeb Database Server Worker In Docker Compose
    #Run Keyword If  '${XW_FORCE_GIT_CLONE}' == 'true'  Git Clone XWtremWeb
    Compile XWtremWeb With Docker Images

Start XWtremWeb Server And XWtremWeb Worker
    Ping XWtremWeb Database
    XWServerDocker.Start XtremWeb Server  ${DIST_XWHEP_PATH}
    XWWorkerDocker.Start XtremWeb Worker  ${DIST_XWHEP_PATH}

Start XWtremWeb Database Server Worker In Docker Compose
    ${created_process} =  Start Process  cd ${DIST_XWHEP_PATH}/docker && ./docker-compose-start.sh  shell=yes  stderr=STDOUT  stdout=${DIST_XWHEP_PATH}/xwhep.docker.compose.process.log
    Wait Until Keyword Succeeds  120 sec  10 sec  XWWorkerDocker.Check XtremWeb Worker Start From Log  ${DIST_XWHEP_PATH}/xwhep.docker.compose.process.log
    XWClientDocker.SetDockerClientImageName  xtremweb/client:${XTREMWEB_VERSION}
    XWClientDocker.SetDockerClientXtremwebPath  ${DIST_XWHEP_PATH}

    

Stop XWtremWeb Database Server Worker In Docker Compose
    DockerHelper.Stop And Remove All Containers

Log XtremWeb Server
    XWServerDocker.Log XtremWeb Server Log File

Log XtremWeb Worker
    XWWorkerDocker.Log XtremWeb Worker Log File

Begin XWtremWeb Command Test In Docker Compose
    #Ping XWtremWeb Database
    #Remove MANDATINGLOGIN in Xtremweb Xlient Conf  ${DIST_XWHEP_PATH}
    Start XWtremWeb Database Server Worker In Docker Compose

End XWtremWeb Command Test In Docker Compose
    Stop XWtremWeb Database Server Worker In Docker Compose
    ${created_process} =  Run Process  docker volume rm xtremweb-data  shell=yes  stderr=STDOUT  stdout=${DIST_XWHEP_PATH}/xwhep.docker.compose.process.log

Clear XWtremWeb Cache
    ${rm_result} =  Run Process  rm -rf ${XW_CACHE_DIR}/XW*  shell=yes
    Should Be Empty  ${rm_result.stderr}
    Should Be Equal As Integers  ${rm_result.rc}  0
    ${rm_result} =  Run Process  rm -rf ${XW_CACHE_DIR}/xw*  shell=yes
    Should Be Empty  ${rm_result.stderr}
    Should Be Equal As Integers  ${rm_result.rc}  0


Git Clone XWtremWeb
    Remove Directory  xtremweb-hep  recursive=true
    ${git_result} =  Run Process  git clone -b ${XW_GIT_BRANCH} ${XW_GIT_URL}  shell=yes
    Log  ${git_result.stderr}
    Log  ${git_result.stdout}
    Should Be Equal As Integers  ${git_result.rc}  0

Compile XWtremWeb With Docker Images
    Create XWCONFIGURE.VALUES FILE  ${RESOURCES_PATH}
    ${compile_result} =  Run Process  cd ${XW_PATH} && ./gradlew  shell=yes  stderr=STDOUT  timeout=340s  stdout=stdoutxwbuild.txt
    Log  ${compile_result.stderr}
    #Should Be Empty    ${compile_result.stderr} some warnings ...
    Log  ${compile_result.stdout}
    Should Be Equal As Integers  ${compile_result.rc}  0
    ${extract_build_successful} =  Get Lines Containing String  ${compile_result.stdout}  BUILD SUCCESSFUL
    ${line_count_build_successful} =  Get Line Count  ${extract_build_successful}
    Should Be Equal As Integers  ${line_count_build_successful}  1
    @{list_directories_dist_path} =  List Directories In Directory  ${DIST_PATH}  xtremweb-*  absolute
    Log  @{list_directories_dist_path}[0]
    Set Suite Variable  ${DIST_XWHEP_PATH}  @{list_directories_dist_path}[0]
    Directory Should Exist  ${DIST_XWHEP_PATH}
    Set Xtremweb Version


Set MANDATINGLOGIN in Xtremweb Xlient Conf
    [Arguments]  ${DIST_XWHEP_PATH}  ${MANDATED}
    Directory Should Exist  ${DIST_XWHEP_PATH}/conf
    Run  sed -i "s/.*MANDATINGLOGIN.*//g" ${DIST_XWHEP_PATH}/conf/xtremweb.client.conf
    Append To File  ${DIST_XWHEP_PATH}/conf/xtremweb.client.conf  MANDATINGLOGIN=${MANDATED}
    Log file  ${DIST_XWHEP_PATH}/conf/xtremweb.client.conf


Remove MANDATINGLOGIN in Xtremweb Xlient Conf
    [Arguments]  ${DIST_XWHEP_PATH}
    Directory Should Exist  ${DIST_XWHEP_PATH}/conf
    Run  sed -i "s/.*MANDATINGLOGIN.*//g" ${DIST_XWHEP_PATH}/conf/xtremweb.client.conf
    Log file  ${DIST_XWHEP_PATH}/conf/xtremweb.client.conf

Curl To Server
    [Arguments]  ${URL}
    ${curl_result} =  Run Process  /usr/bin/curl -v --insecure -X GET -G 'https://${XWCONFIGURE.VALUES.XWServerDocker}:${XWCONFIGURE.VALUES.HTTPSPORT}/${URL}' -d XWLOGIN\=${XWCONFIGURE.VALUES.XWADMINLOGIN} -d XWPASSWD\=${XWCONFIGURE.VALUES.XWADMINPASSWORD}  shell=yes
    Log  ${curl_result.stdout}
    Log  ${curl_result.stderr}
    Should Be Equal As Integers  ${curl_result.rc}  0
    [Return]  ${curl_result.stdout}

Check Work Completed By SubmitTxHash
    [Arguments]  ${submitTxHash}
    ${app_curl_result} =  Curl To Server  getworkbyexternalid/${submitTxHash}
    Log  ${app_curl_result}
    ${lines} =  Get Lines Containing String  ${app_curl_result}  COMPLETED
    ${lines_count} =  Get Line Count  ${lines}
    Should Be Equal As Integers  ${lines_count}  1

Create XWCONFIGURE.VALUES FILE
    [Arguments]  ${DIST_XWHEP_PATH}
    Directory Should Exist  ${DIST_XWHEP_PATH}/conf
    Remove File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values
    Create File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  XWUSER='${XWCONFIGURE.VALUES.XWUSER}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  DBVENDOR='${XWCONFIGURE.VALUES.DBVENDOR}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  DBENGINE='${XWCONFIGURE.VALUES.DBENGINE}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  DBHOST='${XWCONFIGURE.VALUES.DBHOST}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  DBADMINLOGIN='${XWCONFIGURE.VALUES.DBADMINLOGIN}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  DBADMINPASSWORD='${XWCONFIGURE.VALUES.DBADMINPASSWORD}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  DBNAME='${XWCONFIGURE.VALUES.DBNAME}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  DBUSERLOGIN='${XWCONFIGURE.VALUES.DBUSERLOGIN}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  DBUSERPASSWORD='${XWCONFIGURE.VALUES.DBUSERPASSWORD}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  XWADMINLOGIN='${XWCONFIGURE.VALUES.XWADMINLOGIN}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  XWADMINPASSWORD='${XWCONFIGURE.VALUES.XWADMINPASSWORD}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  XWWorkerDockerLOGIN='${XWCONFIGURE.VALUES.XWWorkerDockerLOGIN}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  XWWorkerDockerPASSWORD='${XWCONFIGURE.VALUES.XWWorkerDockerPASSWORD}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  XWVWORKERLOGIN='${XWCONFIGURE.VALUES.XWVWORKERLOGIN}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  XWVWORKERPASSWORD='${XWCONFIGURE.VALUES.XWVWORKERPASSWORD}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  XWServerDocker='${XWCONFIGURE.VALUES.XWServerDocker}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  CERTCN='${XWCONFIGURE.VALUES.CERTCN}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  CERTOU='${XWCONFIGURE.VALUES.CERTOU}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  CERTO='${XWCONFIGURE.VALUES.CERTO}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  CERTL='${XWCONFIGURE.VALUES.CERTL}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  CERTC='${XWCONFIGURE.VALUES.CERTC}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  SSLKEYPASSPHRASE='${XWCONFIGURE.VALUES.SSLKEYPASSPHRASE}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  SSLKEYSERVERPASSWORD='${XWCONFIGURE.VALUES.SSLKEYSERVERPASSWORD}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  SSLTRUSTSTOREPASSWORD='${XWCONFIGURE.VALUES.SSLTRUSTSTOREPASSWORD}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  X509CERTDIR='${XWCONFIGURE.VALUES.X509CERTDIR}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  USERCERTDIR='${XWCONFIGURE.VALUES.USERCERTDIR}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  XWUPGRADEURL='${XWCONFIGURE.VALUES.XWUPGRADEURL}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  HTTPSPORT='${XWCONFIGURE.VALUES.HTTPSPORT}'\n
    Append To File  ${DIST_XWHEP_PATH}/conf/xwconfigure.values  LOGGERLEVEL=INFO\n
    LOG FILE  ${DIST_XWHEP_PATH}/conf/xwconfigure.values

Set Xtremweb Version
    ${result} =  Run Process  basename ${DIST_XWHEP_PATH} | sed s/xtremweb-//g  shell=yes
    Log  ${result.stdout}
    Log  ${result.stderr}
    Should Be Equal As Integers  ${result.rc}   0
    Set Suite Variable  ${XTREMWEB_VERSION}  ${result.stdout}