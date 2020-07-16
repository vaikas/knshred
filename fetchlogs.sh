#!/usr/bin/env bash

# Knative eventing logs for failed e2e tests
# By default assume it's here
PR=
FETCHK8SLOGS=
# Which module to look for in the k8s logs. Defaults to mt-broker-controller 
MODULE="mt-broker-controller"

while [ "$1" != "" ]; do
    case $1 in
        -p | --pr )             shift
                                PR=$1
                                ;;
        -k | --k8slogs )        shift
                                FETCHK8SLOGS="yes"
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if [ "$PR" = "" ]; then
	echo "need to specify which pr with -p"
	exit 1
fi

echo "Making directory for the log files"
`mkdir /tmp/$PR`

echo "Fetching the PR deets from https://github.com/knative/eventing/pull/$PR"
PROWLOGS=`curl -s "https://github.com/knative/eventing/pull/$PR" | grep knative-prow/pr-logs/pull/knative_eventing/$PR/pull-knative-eventing-integration-tests | cut -d '"' -f 2`

echo $PROWLOGS

BASE_MATCHER="gs/knative-prow/pr-logs/pull/knative_eventing/$PR/pull-knative-eventing-integration-tests/"

BASE_DIR=`curl -s $PROWLOGS | grep $BASE_MATCHER | sed 's@gs@https://storage.googleapis.com@' | cut -d '"' -f 2`

echo $BASE_DIR

BUILD_LOGS="$BASE_DIR/build-log.txt"
K8S_LOGS="$BASE_DIR/artifacts/k8s.log.txt"

echo "Fetching the build log: $BUILD_LOGS"
`curl -s -L $BUILD_LOGS > /tmp/$PR/build-log.txt`

if [ "$FETCHK8SLOGS" != "" ]; then
    echo "Fetching the k8s logs (these might be large...): $K8S_LOGS"
    `curl -s -L $K8S_LOGS > /tmp/$PR/k8s.log.txt`
fi

