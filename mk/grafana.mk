#
# Describes operations on the grafana instance.
#

grafana_host ?= https://stats.serlo.local
grafana_user ?= admin
grafana_password ?= admin

export grafana_host
export grafana_user
export grafana_password

.PHONY: dashb-backup
dashb-backup: 
	bash scripts/backup-dashboard.sh author-activity registrations

.PHONY: dashb-restore
dashb-restore:
	bash scripts/restore-dashboard.sh author-activity registrations
