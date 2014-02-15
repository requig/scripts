#!/bin/bash

SOURCE_DIR="$WORKSPACE/androidApp"
TEST_DIR="$WORKSPACE/testAndroidApp"

PATH_APK="$WORKSPACE/tmp"

if [ -d $PATH_APK ]
then
 rm -rf $PATH_APK/*
else
  mkdir $PATH_APK
fi

SOURCE_APP="AndroidCalculator"
TEST_APP="AndroidCalculatorTest"

SOURCE_PACKAGE="com.calculator"
TEST_PACKAGE="com.calculator.test"



cd ${SOURCE_DIR}
android update project -p . --subprojects --target "android-19"

ant -q clean
ant -q debug
cp ${SOURCE_DIR}/bin/${SOURCE_APP}-debug.apk ${PATH_APK}/${SOURCE_APP}.apk

cd ${TEST_DIR}     
android update test-project -p .  -m $SOURCE_DIR
ant -q clean
ant -q debug
cp ${TEST_DIR}/bin/${TEST_APP}-debug.apk ${PATH_APK}/${TEST_APP}.apk



adb shell getprop init.svc.bootanim | grep stopped >/dev/null 2>&1
if [ $? -ne 0 ]
then
	emulator -avd test1 &
	emulatorpid=$!
	adb wait-for-device
fi

#clean
adb logcat -c

#recording...
adb logcat > logcat.txt 2>&1 &
logcatpid=$!


if [ ! -f "${PATH_APK}/${SOURCE_APP}.apk" -o ! -f "${PATH_APK}/${TEST_APP}.apk" ]
then
  echo "No APKs!"
  kill -9 $logcatpid
  exit 13
fi


adb uninstall ${SOURCE_PACKAGE}
adb uninstall ${TEST_PACKAGE}

adb install ${PATH_APK}/${SOURCE_APP}.apk
adb install ${PATH_APK}/${TEST_APP}.apk

adb shell am instrument -w ${TEST_PACKAGE}/com.neenbedankt.android.test.InstrumentationTestRunner


adb pull /data/data/${SOURCE_PACKAGE}/files/TEST-all.xml .
kill -9 $logcatpid

#
# kill -9 $emulatorpid
