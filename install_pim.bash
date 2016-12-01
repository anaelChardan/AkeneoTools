#!/bin/bash

currentPath="$(dirname "$0")"
cd ${currentPath}

scriptPath=`pwd`

folderName=""

pimversion=""
pimedition=""
pimstorage=""
pimengine=""
dockerComposePath=""
scriptsPath="$scriptPath/scripts/"
appFolder=""


###### USER CONFIGURABLE PART ########

#Your docker mapped path containing all your pims
basePath="mnt/Documents/Workspace/Akeneo/PIM"
dockerComposeFileName="docker-compose-not-commitable.yml"
communityRepo="git@github.com:akeneo/pim-community-dev.git"
enterpriseRepo="YOU MUST HAVE YOUR OWN"

#The beggining of your path
akeneoPort="8"
akeneoBehatPort="9"
seleniumPort="5"

#Distinction CE / EE
cePort="5"
eePort="6"

#Distinction ORM / ODM
ormPort="5"
odmPort="6"

#Distinction version Port
oneFourPort="4"
oneFivePort="5"
oneSixPort="6"
masterPort="9"

###### END OF USER CONFIGURABLE PART

function showUsageAndQuit {
   echo "Usage: ./install_pim.bash (1.3|1.4|1.5|1.6|master) (ce|ee) (orm|odm) (php-5.6|php-7.0)"
   exit 1
}

function buildFolderName {
    folderName="${pimversion}_${pimedition}_${pimstorage}_${pimengine}"
    appFolder=${scriptPath}/${folderName}
    dockerComposePath="$appFolder/$dockerComposeFileName"
}

function sedReplaceMac {
  local oldString=$1
  local newString=$2
  local targetFile=$3
  local temp=`mktemp -t sed_replace.XXXXXXXXX`
  chmod ug+rw $temp
  sed -E 's#'${oldString}'#'${newString}'#g' $targetFile > $temp
  mv $temp $targetFile
}

function setupMongo {
  local targetFile=$1
  local temp=`mktemp -t sed_replace.XXXXXXXXX`
  chmod ug+rw ${temp}
  sed -E 's#\/\/ (new Doctrine\\Bundle\\MongoDBBundle\\DoctrineMongoDBBundle)#\1#g' ${targetFile} > ${temp}
  mv ${temp} ${targetFile}
}

function cloneRightVersion {
    if [ ${pimedition} == "ce" ]; then
       echo "############# Clone the PIM Community"
       git clone ${communityRepo} ${folderName}
    else
       echo "############# Clone the PIM Enterprise"
       git clone ${enterpriseRepo} ${folderName}
    fi

    cd ${scriptPath}/${folderName}
    git checkout ${pimversion}
}

function setupPorts {
     echo "############# SETUP ALL YOUR PORTS"

    if [ ${pimedition} == "ce" ]; then
        akeneoPort="${akeneoPort}${cePort}"
        akeneoBehatPort="${akeneoBehatPort}${cePort}"
        seleniumPort="${seleniumPort}${cePort}"
    else
        akeneoPort="${akeneoPort}${eePort}"
        akeneoBehatPort="${akeneoBehatPort}${eePort}"
        seleniumPort="${seleniumPort}${eePort}"
    fi

    if [ ${pimstorage} == "orm" ]; then
        akeneoPort="${akeneoPort}${ormPort}"
        akeneoBehatPort="${akeneoBehatPort}${ormPort}"
        seleniumPort="${seleniumPort}${ormPort}"
    else
        akeneoPort="${akeneoPort}${odmPort}"
        akeneoBehatPort="${akeneoBehatPort}${odmPort}"
        seleniumPort="${seleniumPort}${odmPort}"
    fi

    if [ $pimversion == "1.4" ]
    then
         akeneoPort="${akeneoPort}${oneFourPort}"
         akeneoBehatPort="${akeneoBehatPort}${oneFourPort}"
         seleniumPort="${seleniumPort}${oneFourPort}"
    elif [ $pimversion == "1.5" ]
    then
         akeneoPort="${akeneoPort}${oneFivePort}"
         akeneoBehatPort="${akeneoBehatPort}${oneFivePort}"
         seleniumPort="${seleniumPort}${oneFivePort}"
    elif [ $pimversion == "1.6" ]
    then
         akeneoPort="${akeneoPort}${oneSixPort}"
         akeneoBehatPort="${akeneoBehatPort}${oneSixPort}"
         seleniumPort="${seleniumPort}${oneSixPort}"
    elif [ $pimversion == "master" ]
    then
         akeneoPort="${akeneoPort}${masterPort}"
         akeneoBehatPort="${akeneoBehatPort}${masterPort}"
         seleniumPort="${seleniumPort}${masterPort}"
    fi

    echo "############# Here is your ports : "
    echo "############# akeneoPort: ${akeneoPort}"
    echo "############# akeneoBehatPort: ${akeneoBehatPort}"
    echo "############# akeneoSeleniumPort: ${seleniumPort}"
}

function processFiles {
    echo "############# Copy configuration files"
    cp ${scriptsPath}behat.yml ${appFolder}/
    cp ${scriptsPath}docker-compose-${pimstorage}.yml ${dockerComposePath}
    cp ${scriptsPath}parameters-${pimstorage}.yml ${appFolder}/app/config/parameters.yml
    cp ${scriptsPath}parameters_test-${pimstorage}.yml ${appFolder}/app/config/parameters_test.yml
    rm ${appFolder}/web/app_dev.php
    cp ${scriptsPath}app_dev.php ${appFolder}/web/

    setupPorts

    sedReplaceMac paths ${basePath}/${folderName} ${dockerComposePath}
    sedReplaceMac php-version ${pimengine} ${dockerComposePath}
    sedReplaceMac akeneo_port ${akeneoPort} ${dockerComposePath}
    sedReplaceMac akeneo_behat_port ${akeneoBehatPort} ${dockerComposePath}
    sedReplaceMac akeneo_selenium_port ${seleniumPort} ${dockerComposePath}

    if [ ${pimstorage} == "odm" ]; then
        setupMongo ${appFolder}/app/AppKernel.php
    fi
}

function processInstall {
    cd ${appFolder}
    echo "############# Construct your application using docker"
    docker-compose -f ${dockerComposeFileName} up -d --build
    echo "############# Wait 5 seconds"
    sleep 5
    echo "############# Install your vendors"
    docker-compose -f ${dockerComposeFileName} exec akeneo php -d memory_limit=-1 /usr/local/bin/composer update --ignore-platform-reqs
    echo "############# Install your application for dev usage"
    docker-compose -f ${dockerComposeFileName} exec akeneo pim-initialize
    echo "############# Wait 5 seconds"
    sleep 5
    echo "############# Install your application for test usage (behat)"
    docker-compose -f ${dockerComposeFileName} exec akeneo-behat pim-initialize
    sleep 5
    echo "############# Open the application"
    open http://localhost:${akeneoPort}
}

if [ $# -lt 4 ]; then
   echo "############# Not the right number of parameters"
   showUsageAndQuit
fi

if [ $1 != "1.4" ] && [ $1 != "1.5" ] && [ $1 != "1.6" ] && [ $1 != "master" ]; then
     echo "############# Not supported version"
     showUsageAndQuit
fi
pimversion=$1

if [ $2 != "ce" ] && [ $2 != "ee" ]; then
     echo "############# Not supported edition"
     showUsageAndQuit
fi
pimedition=$2

if [ $3 != "odm" ] && [ $3 != "orm" ]; then
     echo "############# Not supported storage"
     showUsageAndQuit
fi
pimstorage=$3

if [ $4 != "php-5.6" ] && [ $4 != "php-7.0" ]; then
     echo "############# Not supported engine"
     showUsageAndQuit
fi
pimengine=$4

buildFolderName
cloneRightVersion
processFiles
processInstall
