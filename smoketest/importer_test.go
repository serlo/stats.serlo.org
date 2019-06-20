package main

import (
	"strings"
	"testing"
)

//TestImporterCronjob test if mysql importer is working
func TestImporterCronjob(t *testing.T) {
	pattern := "import successful"
	logs, err := getLogs(t, "mysql-importer-cronjob", "mysql-importer-container", 20)
	if err != nil {
		t.Errorf("%s", err.Error())
	}
	if strings.Contains(logs, pattern) {
		return
	}
	t.Errorf("importer logs should have pattern [%s] but logs is [%s]", pattern, logs)
}
