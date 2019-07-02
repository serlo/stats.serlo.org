#
# Various utilities
#

log_arg ?= --follow

PHONY: log_container_%
# show the log for a specific container common implementation
log_container_%:
	for pod in $$(kubectl get pods --namespace kpi | grep ^$* | awk '{ print $$1 }') ; do \
                kubectl logs $$pod --namespace kpi $(log_arg) | sed "s/^/$$pod\ /"; \
        done

.PHONY: log_aggregator
# show the data aggregator log
log_aggregator: kubectl_use_context log_container_aggregator

.PHONY: log_importer
# show the database importer log
log_importer: kubectl_use_context log_container_mysql-importer

.PHONY: log_dbdump
# show the database dump log
log_dbdump: kubectl_use_context log_container_dbdump

.PHONY: log_dbsetup
# show the dbsetup log
log_dbsetup: kubectl_use_context
	pod=$$(kubectl get pods --namespace athene2 | grep ^dbsetup-cronjob | awk '{ print $$1 }'); \
        kubectl logs $$pod --namespace athene2 $(log_arg) | sed "s/^/$$pod\ /"

.PHONY: log_grafana
# show the grafana log
log_grafana: kubectl_use_context log_container_grafana

.PHONY: attach_aggregator_pod
# attach to aggregator pod
attach_aggregator_pod: kubectl_use_context
	kubectl exec -it $(shell kubectl get pods --namespace kpi | grep aggregator | awk '{print $$1}') --namespace kpi /bin/sh


.PHONY: tools_psql_shell
.ONESHELL:
# open a postgres shell
tools_psql_shell: kubectl_use_context
	pod=$$(kubectl get pods --namespace=kpi | grep postgres | awk '{ print $$1 }')
	kubectl exec -it $$pod --namespace=kpi -- su - postgres -c 'psql -d kpi'

