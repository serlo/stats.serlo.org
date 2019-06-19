#
# Various utilities
#


.PHONY: container_log_%
# show the log for a specific container common implementation
tools_container_log_%:
	kubectl logs $$(kubectl get pods --namespace kpi | grep $* | awk '{ print $$1 }') -c $* --namespace kpi --follow

.PHONY: tools_aggregator_log
# show the data aggregator log
tools_aggregator_log: tools_container_log_aggregator

.PHONY: tools_importer_log
# show the database importer log
tools_importer_log: tools_container_log_mysql-importer

.PHONY: tools_provider_log
# show the athene2 content provider log
tools_provider_log: tools_container_log_athene2-content-provider

.PHONY: tools_psql_shell
.ONESHELL:
# open a postgres shell
tools_psql_shell:
	pod=$$(kubectl get pods --namespace=kpi | grep postgres | awk '{ print $$1 }')
	kubectl exec -it $$pod --namespace=kpi -- su - postgres -c psql
