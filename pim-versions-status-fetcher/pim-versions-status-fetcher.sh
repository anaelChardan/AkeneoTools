#!/bin/bash

cd $(dirname $0)

scriptPath=$(pwd)

. ${scriptPath}/etc/fetcher.conf
. ${scriptPath}/fnshs/styles.fnsh

currentDate=$(date +'%m_%d_%Y_%H_%M_%S')
currentFileNameReport="Report_${currentDate}"
reportFolder="${scriptPath}/reports"
currentReportFile="${reportFolder}/${currentFileNameReport}.txt"

function writeInCurrentReport {
    echo $1 >> ${currentReportFile}
}

function doReport {
    cd $1

    git checkout 1.4
    git pull

    writeInCurrentReport ""
    writeInCurrentReport "######## Differences 1.4 and Tag ${last14Tag} ########"
    writeInCurrentReport ""

    git shortlog 1.4 ^${last14Tag} >> ${currentReportFile}

    git checkout 1.5
    git pull

    writeInCurrentReport ""
    writeInCurrentReport "######## Differences 1.4 and Branch 1.5 ########"
    writeInCurrentReport ""

    git shortlog 1.4 ^1.5 >> ${currentReportFile}

    writeInCurrentReport ""
    writeInCurrentReport "######## Differences 1.5 and Tag ${last15Tag} ########"
    writeInCurrentReport ""

    git shortlog 1.5 ^${last15Tag} >> ${currentReportFile}

    git checkout 1.6
    git pull

    writeInCurrentReport ""
    writeInCurrentReport "######## Differences 1.5 and Branch 1.6 ########"
    writeInCurrentReport ""

    git shortlog 1.5 ^1.6 >> ${currentReportFile}

    writeInCurrentReport ""
    writeInCurrentReport "######## Differences 1.6 and Tag ${last16Tag} ########"
    writeInCurrentReport ""

    git shortlog 1.6 ^${last16Tag} >> ${currentReportFile}

    git checkout master
    git pull

    writeInCurrentReport ""
    writeInCurrentReport "######## Differences 1.6 and Branch Master ########"
    writeInCurrentReport ""

    git shortlog 1.6 ^master >> ${currentReportFile}
}


welcomeMessage

echoTitle "Check your PIMs"

if [ ! -d ${pathToYourPimsRepo} ]; then
    echoAction "The Path do your pims repo does not exist, lets create it"
    mkdir -p ${pathToYourPimsRepo}
fi

cd ${pathToYourPimsRepo}

if [ ! -d ${nameOfYourCeVersion} ]; then
    echoAction "Your CE version is not cloned yet, lets clone"
    git clone ${gitRepoCe} ${nameOfYourCeVersion}
fi

if [ ! -d ${nameOfYourEeVersion} ]; then
    echoAction "Your EE version is not cloned yet, lets clone"
    git clone ${gitRepoEe} ${nameOfYourEeVersion}
fi

echoInfo "All your PIMs are synchronized"

writeInCurrentReport "######## Pim Versions Status ${currentFileNameReport} ##########"

echoTitle "Check the CE version"

writeInCurrentReport ""
writeInCurrentReport "######## CE ########"
writeInCurrentReport ""

doReport "${pathToYourPimsRepo}/${nameOfYourCeVersion}"

echoTitle "Check the EE version"

writeInCurrentReport ""
writeInCurrentReport "######## EE ########"
writeInCurrentReport ""

doReport "${pathToYourPimsRepo}/${nameOfYourEeVersion}"

writeInCurrentReport "################################################"

cat ${currentReportFile}
