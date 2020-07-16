#!/usr/bin/env bash

# Where to find the log files at
DIR="/tmp/"
# K8S logs from failed test Artifacts link, then download the artifacts/k8s.log.txt
# By default assume it's here
#K8SLOGS="/tmp/k8s.log.txt"
K8SLOGS=
# Which module to look for in the k8s logs. Defaults to mt-broker-controller 
MODULE="mt-broker-controller"

while [ "$1" != "" ]; do
    case $1 in
        -d | --dir )            shift
                                DIR=$1
                                ;;
        -k | --k8slogs )        shift
				K8SLOGS=$1
                                ;;
        -m | --module )         shift
                                MODULE=$1
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

INFILE="$DIR/build-log.txt"

for i in `grep 'FAIL:' $INFILE  | cut -d ' ' -f 3`
do
    echo "Fetching failures for test fail: $i"
    NAMESPACE=`grep "$i:" $INFILE | grep "namespace is" | cut -d ':' -f 5 | sed 's/"//g' | sed 's/ //g'`
    echo "Found namespace as: $NAMESPACE"

    # Dump the failed tests here
    OUTFILE="$INFILE.$i"
    echo "using test failures outputfile: $OUTFILE"
    `grep "$i:" $INFILE > $INFILE.$i`

    if [ "$K8SLOGS" != "" ]; then
	echo "Processing k8s logs files for $MODULE in $K8SLOGS" 
	# Then grab the k8s logs.
	K8SOUTFILE="$K8SLOGS.$i"
	echo "using k8s outputfile: $K8SOUTFILE"
	# Make this (mt-broker-controller) a flag
	`grep mt-broker-controller $K8SLOGS | grep -e 'Time taken' -e 'Reconciling' -e 'Adding to queue' -e 'successfully acquired lease' -e 'leading' | grep $NAMESPACE > $K8SOUTFILE`
    fi
done