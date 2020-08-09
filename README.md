# Working with DoD CACs
## Preparation
On OSX, make sure you have [brew](https://brew.sh) installed and
that you've installed the following formulas ...

* go
* nss
* openssl

On RHEL, make sure you have the following packages installed ...

* nss-util
* openssl
* go-toolset

## Running
There are two scripts that do all the work.

* `pull-the-certs.sh` populates an NSS database with the DoD root
and intermediate CAs
* `run-simple-server.sh` runs a simple go server listening on port
8443 with mutual TLS and all of the CAs necessary to support CAC
cards. This script writes a `client.pem` file which contains the
received client certificate in DER format.

## Verify certificate chain
Running both of the above scripts enables you to print the `client.pem`
certificate chain using the following command ...

    certutil -A -n client -d nssdb -t u,u,u -i client.pem
    certutil -O -n client -d nssdb

