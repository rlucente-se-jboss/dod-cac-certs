#!/usr/bin/env bash

IFS=$'\n'
for cert in $(certutil -L -d nssdb | grep -i dod | rev | awk '{$1="";print $0}' | rev | sed 's/  *$//g')
do
    echo "************************************************************************"
    echo Validating $cert ...
    echo
    certutil -O -d nssdb -n "$cert"
    echo
done
