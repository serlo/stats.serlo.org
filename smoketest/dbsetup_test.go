package main

import (
	"strings"
	"testing"
)

//TestImporterApp test if mysql importer is working
func TestDBSetupCronjob(t *testing.T) {
	logs, err := getLogs(t, "athene2-dbsetup-cronjob", "dbsetup-container", 20)
	if err != nil {
		t.Errorf("%s", err.Error())
		return
	}
	patterns := []string{"import serlo database was successful", "serlo database exists - nothing to do"}
	for _, pattern := range patterns {
		for _, line := range strings.Split(logs, "\n") {
			if strings.Contains(line, pattern) {
				return
			}
		}
	}
	t.Errorf("dbsetup logs should have patterns [%v] but logs is [%s]", patterns, logs)
}
