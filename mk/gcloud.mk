gcloud_dashboard:
	xdg-open https://console.cloud.google.com/kubernetes/workload?project=serlo-dev&workload_list_tablesize=50 2>/dev/null >/dev/null &

kubectl_use_context:
	kubectl config use-context gke_serlo-$(env_name)_europe-west3-a_serlo-$(env_name)-cluster

