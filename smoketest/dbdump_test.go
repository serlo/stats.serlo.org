package main

import (
	"strings"
	"testing"
)

//TestImporterApp test if mysql importer is working
func TestDBDumpCronjob(t *testing.T) {
	logs, err := getLogs(t, "athene2-dbdump-cronjob", "dbdump-container", 20)
	if err != nil {
		t.Errorf("%s", err.Error())
		return
	}

	pattern := "start with cron pattern [0 4 * * *]"
	for _, line := range strings.Split(logs, "\n") {
		if strings.Contains(line, pattern) {
			return
		}
	}
	t.Errorf("dbdump logs should have pattern [%s] but logs is [%s]", pattern, logs)
}
