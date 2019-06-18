#
# Describes testing operations.
#

.PHONY: project_smoketest
project_smoketest:
	cd smoketest && go run main.go

