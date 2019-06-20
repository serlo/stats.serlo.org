package main

import (
	"fmt"
	"os/exec"
	"strings"
	"testing"
)

func getPodName(t *testing.T, podNamePattern string) string {
	out, err := exec.Command("kubectl", "get", "pods", "--namespace=kpi").CombinedOutput()
	if err != nil {
		t.Errorf("cannot find pod pattern [%s] in output [%s] error [%s]", podNamePattern, out, err.Error())
		return podNamePattern
	}

	return extractPodName(string(out), podNamePattern)
}

func extractPodName(output string, podNamePattern string) string {
	for _, line := range strings.Split(output, "\n") {
		if strings.Contains(line, podNamePattern) {
			return strings.Split(line, " ")[0]
		}
	}
	return podNamePattern
}

func getLogs(t *testing.T, podNamePattern string, containerName string, lines int) (string, error) {
	podName := getPodName(t, podNamePattern)

	out, err := exec.Command("kubectl", "logs", podName, "-c", containerName, fmt.Sprintf("--tail=%d", lines), "--namespace=kpi").CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("cannot get logs from pod [%s] - output [%s] error [%s]", podName, string(out), err.Error())
	}
	return string(out), nil
}
