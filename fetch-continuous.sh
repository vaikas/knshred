#!/usr/bin/env bash

#set -o xtrace

# Knative eventing logs for failed e2e tests
# By default assume it's here
PROWRUN=
FETCHK8SLOGS=
FETCHMETRICSLOGS=
REPO="eventing"

while [ "$1" != "" ]; do
    case $1 in
        -r | --run )            shift
                                PROWRUN=$1
                                ;;
        -k | --k8slogs )        shift
                                FETCHK8SLOGS="yes"
                                ;;
        -m | --metrics )        shift
                                FETCHMETRICSLOGS="yes"
                                ;;
        -r | --repo )           shift
                                REPO=$1
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if [ "$PROWRUN" = "" ]; then
	echo "need to specify which prow run with -r"
	exit 1
fi

echo "Making directory for the log files"
`mkdir /tmp/$PROWRUN`

BUILD_LOG="https://storage.googleapis.com/knative-prow/logs/ci-knative-$REPO-continuous/$PROWRUN/build-log.txt"
`curl -s -L $BUILD_LOG > /tmp/$PROWRUN/build-log.txt`

for LOGFILE in `curl "https://storage.googleapis.com/storage/v1/b/knative-prow/o?prefix=logs/ci-knative-$REPO-continuous/$PROWRUN/artifacts/knative-eventing-logs/" | jq .items[].name | sed 's/"//g'`
do
    echo "LOGFILE: $LOGFILE"
    FILENAME=`echo $LOGFILE | sed 's#.*/##'`
    `curl -s -L "https://storage.googleapis.com/knative-prow/$LOGFILE" > /tmp/$PROWRUN/$FILENAME`
done


