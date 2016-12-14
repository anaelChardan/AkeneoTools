#!/bin/bash

#Files and Project
pimsPath="/Users/Ananas/Documents/Workspace/Akeneo/PIM"
dockerComposeFileName="docker-compose-not-commitable.yml"

#Github
communityRepo="git@github.com:akeneo/pim-community-dev.git"
enterpriseRepo="git@github.com:akeneo/pim-enterprise-dev.git"

#The beginning of your path
akeneoPHP5Port="6"
akeneoPHP7Port="7"
akeneoPHP5BehatPort="8"
akeneoPHP7BehatPort="9"
seleniumPHP5Port="4"
seleniumPHP7Port="5"

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
