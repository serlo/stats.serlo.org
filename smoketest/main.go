package main

import (
	"crypto/tls"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"regexp"
	"strings"
	"time"
)

var grafanaURL = "https://stats.serlo.local/login"

var netClient *http.Client

func main() {
	setupHTTPCLient()
	checkEtcHosts()
	validateGrafanaLoginPage()
	fmt.Printf("tests successful\n")
}

func setupHTTPCLient() {
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	netClient = &http.Client{
		Timeout:   time.Second * 10,
		Transport: tr,
	}
}

func checkEtcHosts() {
	fmt.Printf("check etc hosts\n")
	file, err := ioutil.ReadFile("/etc/hosts")
	if err != nil {
		fail("cannot read /etc/hosts file", err)
	}
	if !strings.Contains(string(file), "stats.serlo.local") {
		fail("/etc/hosts does not contain host definition stats.serlo.local please add", nil)
	}
}

func validateGrafanaLoginPage() {
	fmt.Printf("validate grafana login\n")
	response, err := netClient.Get(grafanaURL)
	if err != nil {
		fail("grafana login https request failed ", err)
	}
	defer response.Body.Close()

	body, err := ioutil.ReadAll(response.Body)
	if err != nil {
		fail("grafana reading login response failed", err)
	}
	pattern := regexp.MustCompile(".grafana-app.class..grafana-app.*")
	if err != nil {
		fail("grafana matching login page failed", err)
	}

	if pattern.FindString(string(body)) == "" {
		fail(fmt.Sprintf("grafana login page does not match pattern [%s]", pattern.String()), nil)
	}
}

func fail(message string, err error) {
	if err != nil {
		fmt.Printf("FAIL: %s error [%s]\n", message, err.Error())
	}
	fmt.Printf("FAIL: %s\n", message)

	os.Exit(1)
}
