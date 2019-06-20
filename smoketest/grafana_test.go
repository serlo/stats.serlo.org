package main

import (
	"io/ioutil"
	"regexp"
	"testing"
)

var grafanaURL = "https://stats.serlo.local/login"

//TestGrafanaApp test if grafana is working
func TestGrafanaApp(t *testing.T) {
	setupHTTPCLient()

	response, err := netClient.Get(grafanaURL)
	if err != nil {
		t.Errorf("grafana login https request failed [%s]", err)
		return
	}
	defer response.Body.Close()

	body, err := ioutil.ReadAll(response.Body)
	if err != nil {
		t.Errorf("grafana reading login response failed [%s]", err)
		return
	}
	pattern := regexp.MustCompile(".grafana-app.class..grafana-app.*")
	if err != nil {
		t.Errorf("grafana matching login page failed [%s]", err)
		return
	}

	if pattern.FindString(string(body)) == "" {
		t.Errorf("grafana login page does not match pattern [%s]", pattern.String())
	}
}
