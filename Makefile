#
# Makefile
# 
# Purpose:
# - automate the upload and backup of current grafana dashboards
# - run smoke tests agains local minikube cluster or gcloud dev/staging/production
# 

grafana_host ?= https://stats.dev.serlo.local
export grafana_host
grafana_user ?= admin
export grafana_user
grafana_password ?= admin
export grafana_password

.PHONY: dashb-backup
dashb-backup: 
	bash scripts/backup-dashboard.sh author-activity registrations

.PHONY: dashb-restore
dashb-restore:
	bash scripts/restore-dashboard.sh author-activity registrations

image-export:
	#push local development images to minikube
	eval $$(minikube docker-env) && $(MAKE) -C mysql-importer docker-build

.PHONY: smoketest
smoketest:
	cd smoketest && go run main.go

mysql-importer-run:
	$(MAKE) -c importer run-once
