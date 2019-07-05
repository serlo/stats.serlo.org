#
# Describes operations on the grafana instance.
#

export grafana_user ?= admin

ifeq ($(env_name),minikube)
	export grafana_host ?= https://stats.serlo.local
	export grafana_password ?= admin
	export grafana_serlo_password ?= serlo
endif
ifeq ($(env_name),dev)
	export grafana_host ?= http://stats.serlo-development.dev
endif
ifeq ($(env_name),staging)
	export grafana_host ?= https://stats.serlo-staging.dev
endif

ifneq ($(env_name),minikube)
	export grafana_password ?= $(shell cat $(infrastructure_repository)/live/$(env_name)/secrets/terraform-$(env_name).tfvars | grep kpi_grafana_admin_password | awk '{ print $$3}' | sed 's/\"//g')
endif

.PHONY: grafan_backup_dashboards
# download grafana dashboards to the repository
grafana_backup_dashboards: 
	bash scripts/backup-dashboard.sh

.PHONY: grafana_restore_dashboards
# load grafana dashboards to $grafana_host
grafana_restore_dashboards:
	bash scripts/restore-dashboard.sh

.ONESHELL:
.PHONY: grafana_add_default_users
# add the default users to grafana
grafana_add_default_users:
	@params="-k -u $(grafana_user):$(grafana_password)"
	@curl -s $$params -XGET $(grafana_host)/api/users | grep serlo >/dev/null && echo "user serlo already created" && exit 0
	@curl -s $$params -XPOST -H 'Content-Type: application/json' -d "{\"name\":\"serlo\",\"email\":\"kpi-user@serlo.org\",\"login\":\"serlo\",\"password\":\"$(grafana_serlo_password)\"}" \
			$(grafana_host)/api/admin/users >/dev/null && echo "user serlo created"
