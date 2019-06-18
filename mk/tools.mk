#
# Various utilities
#


# show the log for a specific container common implementation
.PHONY: container_log_%
tools_container_log_%:
	kubectl logs $$(kubectl get pods --namespace kpi | grep $* | awk '{ print $$1 }') -c $* --namespace kpi --follow

.PHONY: tools_importer_log
tools_importer_log: tools_container_log_mysql-importer

.PHONY: tools_provider_log
tools_provider_log: tools_container_log_athene2-content-provider

# open a postgres shell
.PHONY: tools_psql_shell
.ONESHELL:
tools_psql_shell:
	pod=$$(kubectl get pods --namespace=kpi | grep postgres | awk '{ print $$1 }')
	kubectl exec -it $$pod --namespace=kpi -- su - postgres -c psql
