package main

import (
	"crypto/tls"
	"crypto/x509"
	"io"
	"io/ioutil"
	"log"
	"net/http"
)

func helloHandler(w http.ResponseWriter, r *http.Request) {
	// Write "Hello, world!" to the response body
	io.WriteString(w, "Hello, world!\n")
	ioutil.WriteFile("client.pem", r.TLS.PeerCertificates[0].Raw, 0644)
}

func main() {
	// Set up a /hello resource handler
	http.HandleFunc("/hello", helloHandler)

	// Create a CA certificate pool and add CAs to it
	caList := []string{"AllCerts.pem", "RootCert2.pem", "RootCert3.pem", "RootCert4.pem", "RootCert5.pem", "ca.cert.pem", "intermediate.cert.pem"}
	caCertPool := x509.NewCertPool()

	for _, ca := range caList {
		caCert, err := ioutil.ReadFile("CAs/" + ca)
		if err != nil {
			log.Fatal(err)
		}
		caCertPool.AppendCertsFromPEM(caCert)
	}

	// Create the TLS Config with the CA pool and enable Client certificate validation
	tlsConfig := &tls.Config{
		ClientCAs:  caCertPool,
		ClientAuth: tls.RequireAndVerifyClientCert,
	}
	tlsConfig.BuildNameToCertificate()

	// Create a Server instance to listen on port 8443 with the TLS config
	server := &http.Server{
		Addr:      ":8443",
		TLSConfig: tlsConfig,
	}

	// Listen to HTTPS connections with the server certificate and wait
	log.Fatal(server.ListenAndServeTLS("certs/server.pem", "certs/server.key"))
}
