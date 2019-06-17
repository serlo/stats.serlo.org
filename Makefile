#
# Makefile for local development for the serlo KPI project.
# 


infrastructure_repository ?= ../infrastructure/

include mk/grafana.mk
include mk/test.mk
include mk/deploy.mk

.PHONY: deploy
deploy: provide_athene2_content restore_dashboards

.PHONY: launch
launch: deploy
	xdg-open $(grafana_host)/login 2>/dev/null >/dev/null &
