package main

import (
	"crypto/tls"
	"net/http"
	"time"
)

func main() {
}

var netClient *http.Client

func setupHTTPCLient() {
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	netClient = &http.Client{
		Timeout:   time.Second * 10,
		Transport: tr,
	}
}
