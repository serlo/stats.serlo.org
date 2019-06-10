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

.PHONY: smoketest
smoketest:
	cd test && go run main.go
