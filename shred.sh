#!/usr/bin/env bash

#set -o xtrace

# Where to find the log files at
DIR="/tmp/"
# K8S logs from failed test Artifacts link, then download the artifacts/k8s.log.txt
# By default assume it's here
K8SLOGS=
# Which module to look for in the k8s logs. Defaults to all
MODULE=

while [ "$1" != "" ]; do
    case $1 in
        -d | --dir )            shift
                                DIR=$1
                                ;;
        -k | --k8slogs )        shift
				K8SLOGS="yes"
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
K8SFILE="$DIR/k8s.log.txt"

for i in `grep 'FAIL:' $INFILE | sed 's/^ *//g' | cut -d ' ' -f 3`
do
    echo "Fetching failures for test fail: $i"

    `./shred -file $INFILE -test $i`

    CLEANTESTNAME=`echo $i | sed 's@/@-@g'`
    OUTFILE="$INFILE.$CLEANTESTNAME"

    if [ "$K8SLOGS" == "" ]; then
	continue
    fi

    NAMESPACE=`grep "namespace is" $OUTFILE | cut -d ':' -f 4 | sed 's/"//g' | sed 's/ //g'`

    if [ "$NAMESPACE" = "" ]; then
	echo "No namespace (probably enclosing test) found for $i, skipping"
	continue
    fi

    echo "Found namespace as: $NAMESPACE"
    echo "Processing k8s logs files for $MODULE in $K8SFILE"
    # Then grab the k8s logs.
    K8SOUTFILE="$K8SFILE.$CLEANTESTNAME"
    echo "using k8s outputfile: $K8SOUTFILE"
    if [ "$MODULE" != "" ]; then
	`grep $MODULE $K8SFILE | grep $NAMESPACE > $K8SOUTFILE`
    else
	# no module, grab all
	`grep $NAMESPACE $K8SFILE > $K8SOUTFILE`
    fi
done
