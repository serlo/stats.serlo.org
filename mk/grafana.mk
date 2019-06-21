#
# Describes operations on the grafana instance.
#

export grafana_user ?= admin

ifeq ($(env_name),minikube)
	export grafana_host ?= https://stats.serlo.local
	export grafana_password ?= admin
endif

ifeq ($(env_name),dev)
	export grafana_host ?= http://stats.serlo-development.dev
	export grafana_password ?= $(shell cat $(infrastructure_repository)/live/dev/secrets/terraform-dev.tfvars | grep kpi_grafana_admin_password | awk '{ print $$3}' | sed 's/\"//g')
endif

.PHONY: backup_dashboards
# download grafana dashboards to the repository
backup_dashboards: 
	bash scripts/backup-dashboard.sh

.PHONY: restore_dashboards
# load grafana dashboards to $grafana_host
restore_dashboards:
	bash scripts/restore-dashboard.sh
