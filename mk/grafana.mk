#
# Describes operations on the grafana instance.
#

grafana_host ?= https://stats.serlo.local
grafana_user ?= admin
grafana_password ?= admin

export grafana_host
export grafana_user
export grafana_password

.PHONY: backup_dashboards
backup_dashboards: 
	bash scripts/backup-dashboard.sh author-activity registrations

.PHONY: restore_dashboards
restore_dashboards:
	bash scripts/restore-dashboard.sh author-activity registrations
