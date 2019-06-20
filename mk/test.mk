#
# Describes testing operations.
#

.PHONY: project_smoketest
# run smoketest for kpi project
project_smoketest:
	$(MAKE) -C smoketest

