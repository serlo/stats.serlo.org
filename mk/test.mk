#
# Describes testing operations.
#

.PHONY: smoketest
smoketest:
	cd smoketest && go run main.go

.PHONY: mysql-importer-run
mysql-importer-run:
	$(MAKE) -c mysql-importer run-once
