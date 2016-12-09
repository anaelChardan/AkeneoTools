#!/bin/bash

SECONDS=0
currentPath="$(dirname "$0")"
cd ${currentPath}
currentAbsolutePath=`pwd`

. ${currentAbsolutePath}/files/config/installer/parameters.bash

dockerFilesPath="${currentAbsolutePath}/files/config/docker/"
pimFilesPath="${currentAbsolutePath}/files/config/pim/"


####### WILL BE UPDATED
folderName=""
pimversion=""
pimedition=""
pimstorage=""
pimengine=""
dockerComposePath=""
appFolder=""
akeneoPort=""
akeneoBehatPort=""
seleniumPort=""

function showUsageAndQuit {
   echo "Usage: ./install_pim.bash (1.4|1.5|1.6|master) (ce|ee) (orm|odm) (php-5.6|php-7.0)"
   exit 1
}

function buildFolderName {
    folderName="${pimversion}_${pimedition}_${pimstorage}_${pimengine}"
    appFolder=${currentAbsolutePath}/${folderName}
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
        if [ ! -d "pim-community-dev" ]; then
            echo "############# Clone the PIM Community as cache"
            git clone ${communityRepo}
        fi

        cd pim-community-dev
        git pull
        cd ${currentAbsolutePath}
        cp -R pim-community-dev ${folderName}
    else
        if [ ! -d "pim-enterprise-dev" ]; then
            echo "############# Clone the PIM Enterprise as cache"
            git clone ${enterpriseRepo}
        fi
        cd pim-enterprise-dev
        git pull
        cd ${currentAbsolutePath}
        cp -R pim-enterprise-dev ${folderName}
    fi

    cd ${currentAbsolutePath}/${folderName}
    git checkout ${pimversion}
    git pull
}

function setupPorts {
    echo "############# SETUP ALL YOUR PORTS"

    if [ ${pimengine} == "php-5.6" ]; then
       akeneoPort="${akeneoPHP5Port}"
       akeneoBehatPort="${akeneoPHP5BehatPort}"
       seleniumPort="${seleniumPHP5Port}"
    else
       akeneoPort="${akeneoPHP7Port}"
       akeneoBehatPort="${akeneoPHP7BehatPort}"
       seleniumPort="${seleniumPHP7Port}"
    fi

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
}

function processFiles {
    echo "############# Copy configuration files"

    cp ${pimFilesPath}behat.yml ${appFolder}/
    cp ${pimFilesPath}parameters-${pimstorage}.yml ${appFolder}/app/config/parameters.yml
    cp ${pimFilesPath}parameters-${pimstorage}.yml ${appFolder}/app/config/parameters.yml.dist
    cp ${pimFilesPath}parameters_test-${pimstorage}.yml ${appFolder}/app/config/parameters_test.yml

    rm ${appFolder}/web/app_dev.php
    cp ${pimFilesPath}app_dev.php ${appFolder}/web/

    mkdir -p ${appFolder}/docker-provisionning

    cp ${dockerFilesPath}docker-compose-${pimstorage}.yml ${dockerComposePath}
    cp ${dockerFilesPath}Dockerfile-akeneo-${pimengine} ${appFolder}/docker-provisionning/Dockerfile-akeneo
    cp ${dockerFilesPath}Dockerfile-akeneo-${pimengine} ${appFolder}/docker-provisionning/Dockerfile-akeneo-behat

    setupPorts

    sedReplaceMac /paths ${pimsPath}/${folderName} ${dockerComposePath}

    sedReplaceMac image_name akeneo ${appFolder}/docker-provisionning/Dockerfile-akeneo
    sedReplaceMac image_name akeneo-behat ${appFolder}/docker-provisionning/Dockerfile-akeneo-behat
    sedReplaceMac akeneo_port ${akeneoPort} ${dockerComposePath}
    sedReplaceMac akeneo_behat_port ${akeneoBehatPort} ${dockerComposePath}
    sedReplaceMac akeneo_selenium_port ${seleniumPort} ${dockerComposePath}
    sedReplaceMac phpstorm_localhost localhost_${folderName} ${dockerComposePath}
    sedReplaceMac phpstorm_localhost_behat localhost_behat_${folderName} ${dockerComposePath}

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
    echo "############# Use the PHP on your host because of slow issues in docker for mac"
    if [ ${pimengine} == "php-5.6" ]; then
        docker-compose -f ${dockerComposeFileName} exec --user root akeneo php5dismod -s cli xdebug
        docker-compose -f ${dockerComposeFileName} exec akeneo php -d memory_limit=-1 /usr/local/bin/composer update --ignore-platform-reqs --optimize-autoloader --prefer-dist
        docker-compose -f ${dockerComposeFileName} exec --user root akeneo php5enmod -s cli xdebug
    else
        docker-compose -f ${dockerComposeFileName} exec --user root akeneo phpdismod -s cli xdebug
        docker-compose -f ${dockerComposeFileName} exec akeneo php -d memory_limit=-1 /usr/local/bin/composer update --ignore-platform-reqs --optimize-autoloader --prefer-dist
        docker-compose -f ${dockerComposeFileName} exec --user root akeneo phpenmod -s cli xdebug
    fi

    echo "############# Install your application for test usage (behat)"
    docker-compose -f ${dockerComposeFileName} exec akeneo-behat pim-initialize
    echo "############# Wait 5 seconds"
    sleep 15
    echo "############# Install your application for dev usage"
    docker-compose -f ${dockerComposeFileName} exec akeneo pim-initialize
    sleep 30
    echo "############# Open the application"
    open http://localhost:${akeneoPort}
}

function printReport {
    duration=$SECONDS
    echo "PIM INSTALLATION : $(($duration / 60)) minutes and $(($duration % 60)) seconds."
    echo "############# Here are your ports : "
    echo "############# akeneoPort: ${akeneoPort}"
    echo "############# akeneoBehatPort: ${akeneoBehatPort}"
    echo "############# akeneoSeleniumPort: ${seleniumPort}"
    cd ${appFolder}
    docker-compose -f ${dockerComposeFileName} ps
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

echo "PIM INSTALLATION WILL PROCEED UNLEASH PIM POWEEEEERRRRR"

buildFolderName
cloneRightVersion
processFiles
processInstall
printReport
