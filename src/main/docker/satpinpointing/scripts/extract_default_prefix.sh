#!/bin/bash

PREFIX=$1
INPUT_FILE=$2

if grep '\s*Prefix\s*(\s*:\s*=.*' $INPUT_FILE
then
	echo "Default prefix is already defined !!!"
	exit 1
fi

# TODO: write the prefix at the beginning !!!
echo "Prefix(:=<$PREFIX>)"
sed "s|<$PREFIX\([^>/#]*\)>|:\1|g" $INPUT_FILE
