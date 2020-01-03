#
# Various utilities
#

log_arg ?= --follow

.PHONY: list_pods
# List all container images of the kubernetes cluster
list_pods:
	kubectl get pods --all-namespaces

.PHONY: log_container_%
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

.PHONY: attach_pod_%
# open a shell on pod $*
attach_pod_%: kubectl_use_context
	kubectl exec -it $$(kubectl get pods --namespace kpi | grep "$*" | awk '{print $$1}') --namespace kpi /bin/sh

.PHONY: psql_shell
# open a postgres shell
psql_shell: kubectl_use_context
	pod=
	kubectl exec -it \
		$$(kubectl get pods --namespace=kpi | grep postgres | awk '{ print $$1 }') \
	--namespace=kpi -- su - postgres -c 'psql -d kpi'

.PHONY: deploy_%
# force re-deployment of {aggregator-cronjob|mqsql-importer-cronjob|grafana_deployment}
deploy_%:
	bash -c "cd minikube && terraform taint module.kpi.kubernetes_deployment.$*"
	$(MAKE) terraform_apply

.PHONY: gcloud_dashboard
# open the gcloud dashboard
gcloud_dashboard:
	xdg-open https://console.cloud.google.com/kubernetes/workload?project=serlo-dev&workload_list_tablesize=50 2>/dev/null >/dev/null &

.PHONY: gcloud_kubectl_context_%
# switch to the gcloud kubectl context $* (dev,staging,production). 
gcloud_kubectl_context_%:
	kubectl config use-context gke_serlo-$*_europe-west3-a_serlo-$*-cluster

