#
# Describes testing operations.
#

.PHONY: project_smoketest
# run a quick importer smote test
project_smoketest:
	cd smoketest && go run main.go

