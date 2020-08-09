#!/usr/bin/env bash

for bundle in AllCerts.p7b RootCert2.cer RootCert3.cer RootCert4.cer RootCert5.cer
do
    curl -sLO https://militarycac.com/maccerts/$bundle
done

WORKDIR=$(pushd $(dirname $0) &> /dev/null && pwd && popd &> /dev/null)
NSSDB=$WORKDIR/nssdb

# initialize the NSS database
rm -fr $NSSDB
mkdir $NSSDB
certutil -N -d $NSSDB --empty-password

# set temporary import/export password
echo 'admin1redhat!' > password.txt

# import the root CAs
for bundle in RootCert2 RootCert3 RootCert4 RootCert5
do
	openssl x509 -in $bundle.cer -inform DER -out $bundle.pem -outform PEM
	openssl pkcs12 -export -nokeys -in $bundle.pem -out $bundle.p12 -password file:password.txt
	pk12util -d $NSSDB -i $bundle.p12 -w password.txt
done

# import the intermediate CAs
openssl pkcs7 -print_certs -inform der -in AllCerts.p7b -out AllCerts.pem
openssl pkcs12 -export -nokeys -in AllCerts.pem -out AllCerts.p12 -password file:password.txt
pk12util -d $NSSDB -i AllCerts.p12 -w password.txt

# update the trust attributes to CT,C,C for all the certs
IFS=$'\n'
for cert in $(certutil -L -d $NSSDB -h all | grep Government | sed 's/\(Government\).*/\1/g')
do
	certutil -M -n "$cert" -d $NSSDB -t CT,C,C
done

# dump the certificates
certutil -L -d $NSSDB -h all

# delete the temporary files
ls password.txt *.cer *.p7b *.pem *.p12 | grep -v client.pem | xargs rm -f

