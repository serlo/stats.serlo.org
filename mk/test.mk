#
# Describes testing operations.
#

.PHONY: project_smoketest
# run smoketest for kpi project
project_smoketest: kubectl_use_context
	$(MAKE) -C smoketest

