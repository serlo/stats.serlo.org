#
# Various utilities
#


.PHONY: tools_container_log_%
# show the log for a specific container common implementation
tools_container_log_%:
	namespace=$$(kubectl get pods --all-namespaces | grep $* | awk '{ print $$1 }') ; \
	pod=$$(kubectl get pods --namespace=$$namespace | grep $* | awk '{ print $$1 }') ; \
	kubectl logs $$pod --all-containers=true --namespace=$$namespace --follow

.PHONY: tools_aggregator_log
# show the data aggregator log
tools_aggregator_log: kubectl_use_context tools_container_log_aggregator

.PHONY: tools_importer_log
# show the database importer log
tools_importer_log: kubectl_use_context tools_container_log_mysql-importer

.PHONY: tools_dbdump_log
# show the database dump log
tools_dbdump_log: kubectl_use_context tools_container_log_dbdump

.PHONY: tools_dbsetup_log
# show the dbsetup log
tools_dbsetup_log: kubectl_use_context tools_container_log_dbsetup

.PHONY: tools_grafana_log
# show the grafana log
tools_grafana_log: kubectl_use_context tools_container_log_grafana

.PHONY: tools_psql_shell
.ONESHELL:
# open a postgres shell
tools_psql_shell: kubectl_use_context
	pod=$$(kubectl get pods --namespace=kpi | grep postgres | awk '{ print $$1 }')
	kubectl exec -it $$pod --namespace=kpi -- su - postgres -c 'psql -d kpi'

