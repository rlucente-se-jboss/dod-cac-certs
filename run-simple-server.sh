#!/usr/bin/env bash

# work in current script directory
WORKDIR=$(pushd $(dirname $0) &> /dev/null && pwd && popd &> /dev/null)
pushd $WORKDIR &> /dev/null

rm -fr certs CAs
mkdir certs CAs

echo
echo "Get DoD root and intermediate CAs ... "

# pull the DoD root and intermediate CAs
for bundle in AllCerts.p7b RootCert2.cer RootCert3.cer RootCert4.cer RootCert5.cer
do
    curl -sLO https://militarycac.com/maccerts/$bundle
done

# import the DoD root CAs
for bundle in RootCert2 RootCert3 RootCert4 RootCert5
do
	openssl x509 -in $bundle.cer -inform DER -out CAs/$bundle.pem -outform PEM
    rm $bundle.cer
done

# import the DoD intermediate CAs
openssl pkcs7 -print_certs -inform der -in AllCerts.p7b -out CAs/AllCerts.pem
rm AllCerts.p7b

echo Create temporary root CA, intermediate CA, and server cert and key ...

rm -fr intranet-test-certs
git clone https://github.com/rlucente-se-jboss/intranet-test-certs.git \
    &> /dev/null
pushd intranet-test-certs &> /dev/null

./02-create-root-pair.sh &> /dev/null
./03-create-intermediate-pair.sh &> /dev/null
./04-create-server-pair.sh &> /dev/null
./05-create-client-pair.sh &> /dev/null
./06-export-certs.sh &> /dev/null

# set temporary import/export password
echo 'admin1jboss!' > password.txt

openssl pkcs12 -in server.p12 -nodes -nocerts \
    -password file:password.txt 2> /dev/null | \
    openssl rsa -out server.key &> /dev/null
openssl pkcs12 -in server.p12 -out server.pem -nokeys \
    -password file:password.txt &> /dev/null

rm -f password.txt

cp ca.cert.pem ../CAs
cp intermediate.cert.pem ../CAs
mv server.key server.pem ../certs

popd &> /dev/null

IPADDR=localhost
if [[ "$(uname -s)" = "Darwin" ]]
then
    IPADDR=$(ifconfig | grep 'inet [0-9]' | grep -v 127.0.0.1 | awk '{print $2; exit}')
elif [[ "$(uname -s)" = "Linux" ]]
then
    IPADDR=$(ip a s | grep 'inet [0-9]' | grep -v 127.0.0.1 | awk '{print $2; exit}' | cut -d/ -f1)
fi

sudo firewall-cmd --add-port=8443/tcp

echo
echo Server running at https://$IPADDR:8443/hello
echo Stop the server using CTRL-C
echo

go run server.go

popd &> /dev/null

