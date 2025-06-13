#!/bin/bash

TARGET_WAR=~/Downloads/genie
TARGET_FE=angular

rm -rf "${TARGET_FE}"
mkdir "${TARGET_FE}"

cp -a "${TARGET_WAR}.war" "${TARGET_FE}/"
cd "${TARGET_FE}"
jar -xvf genie.war
rm genie.war
