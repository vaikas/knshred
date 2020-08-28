#!/usr/bin/env bash

# set -o xtrace

# Knative eventing logs for failed e2e tests
# By default assume it's here
PR=
FETCHK8SLOGS=
FETCHMETRICSLOGS=
REPO="eventing"

while [ "$1" != "" ]; do
    case $1 in
        -p | --pr )             shift
                                PR=$1
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

if [ "$PR" = "" ]; then
	echo "need to specify which pr with -p"
	exit 1
fi

echo "Making directory for the log files"
`mkdir /tmp/$PR`

echo "Fetching the integration tests PR deets from https://github.com/knative/$REPO/pull/$PR"
PROWLOGS=`curl -s "https://github.com/knative/$REPO/pull/$PR" | grep knative-prow/pr-logs/pull/knative_$REPO/$PR/pull-knative-$REPO-integration-tests | cut -d '"' -f 2`

echo $PROWLOGS

if [ "$PROWLOGS" == "" ]; then
    echo "Did not find integration failures, skipping..."
else 
    INTEGRATION_BASE_MATCHER="gs/knative-prow/pr-logs/pull/knative_$REPO/$PR/pull-knative-$REPO-integration-tests/"
    INTEGRATION_BASE_DIR=`curl -s $PROWLOGS | grep $INTEGRATION_BASE_MATCHER | sed 's@gs@https://storage.googleapis.com@' | cut -d '"' -f 2`

     echo $INTEGRATION_BASE_DIR
     INTEGRATION_BUILD_LOGS="$INTEGRATION_BASE_DIR/build-log.txt"
     echo "Fetching the build log: $INTEGRATION_BUILD_LOGS"
     `curl -s -L $INTEGRATION_BUILD_LOGS > /tmp/$PR/integration-build-log.txt`

     INTEGRATION_K8S_LOGS="$INTEGRATION_BASE_DIR/artifacts/k8s.log.txt"
     if [ "$FETCHK8SLOGS" != "" ]; then
         echo "Fetching the k8s logs (these might be large...): $INTEGRATION_K8S_LOGS"
         `curl -s -L $INTEGRATION_K8S_LOGS > /tmp/$PR/integration-k8s.log.txt`
     fi

     INTEGRATION_METRICS_LOGS="$INTEGRATION_BASE_DIR/artifacts/k8s.metrics.txt"
     if [ "$FETCHMETRICSLOGS" != "" ]; then
         echo "Fetching the metrics logs (these might be large...): $METRICS_LOGS"
        `curl -s -L $INTEGRATION_METRICS_LOGS > /tmp/$PR/integration-k8s.metrics.txt`
     fi

     # Then fetch the knative-eventing logs.
     DIR_PATH=`echo "$INTEGRATION_BASE_DIR" | sed 's#.*storage.googleapis.com/knative-prow/##'`
     echo "DIR_PATH: $DIR_PATH"
     for LOGFILE in `curl "https://storage.googleapis.com/storage/v1/b/knative-prow/o?prefix=$DIR_PATH/artifacts/knative-eventing-logs/" | jq .items[].name | sed 's/"//g'`
     do
	 FILENAME=`echo $LOGFILE | sed 's#.*/##'`
	 `curl -s -L "https://storage.googleapis.com/knative-prow/$LOGFILE" > /tmp/$PR/$FILENAME`
     done
fi

echo "Fetching the conformance tests PR deets from https://github.com/knative/$REPO/pull/$PR"
PROWLOGS=`curl -s "https://github.com/knative/$REPO/pull/$PR" | grep knative-prow/pr-logs/pull/knative_$REPO/$PR/pull-knative-$REPO-conformance-tests | cut -d '"' -f 2`

echo $PROWLOGS

if [ "$PROWLOGS" == "" ]; then
    echo "Did not find conformance failures, skipping..."
else 
    CONFORMANCE_BASE_MATCHER="gs/knative-prow/pr-logs/pull/knative_$REPO/$PR/pull-knative-$REPO-conformance-tests/"
    CONFORMANCE_BASE_DIR=`curl -s $PROWLOGS | grep $CONFORMANCE_BASE_MATCHER | sed 's@gs@https://storage.googleapis.com@' | cut -d '"' -f 2`

     echo $CONFORMANCE_BASE_DIR
     CONFORMANCE_BUILD_LOGS="$CONFORMANCE_BASE_DIR/build-log.txt"
     echo "Fetching the build log: $CONFORMANCE_BUILD_LOGS"
     `curl -s -L $CONFORMANCE_BUILD_LOGS > /tmp/$PR/conformance-build-log.txt`

     CONFORMANCE_K8S_LOGS="$CONFORMANCE_BASE_DIR/artifacts/k8s.log.txt"
     if [ "$FETCHK8SLOGS" != "" ]; then
         echo "Fetching the k8s logs (these might be large...): $CONFORMANCE_K8S_LOGS"
         `curl -s -L $CONFORMANCE_K8S_LOGS > /tmp/$PR/conformance-k8s.log.txt`
     fi

     CONFORMANCE_METRICS_LOGS="$CONFORMANCE_BASE_DIR/artifacts/k8s.metrics.txt"
     if [ "$FETCHMETRICSLOGS" != "" ]; then
         echo "Fetching the metrics logs (these might be large...): $METRICS_LOGS"
        `curl -s -L $CONFORMANCE_METRICS_LOGS > /tmp/$PR/conformance-k8s.metrics.txt`
     fi

     # Then fetch the knative-eventing logs.
     DIR_PATH=`echo "$CONFORMANCE_BASE_DIR" | sed 's#.*storage.googleapis.com/knative-prow/##'`
     for LOGFILE in `curl "https://storage.googleapis.com/storage/v1/b/knative-prow/o?prefix=$DIR_PATH/artifacts/knative-eventing-logs/" | jq .items[].name | sed 's/"//g'`
     do
	 FILENAME=`echo $LOGFILE | sed 's#.*/##'`
	 `curl -s -L "https://storage.googleapis.com/knative-prow/$LOGFILE" > /tmp/$PR/$FILENAME`
     done	 
fi
