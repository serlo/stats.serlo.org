#
# Makefile for local development for the serlo KPI project.
# 


infrastructure_repository ?= ../infrastructure/

ifeq ($(env_name),minikube)
	include mk/minikube.mk
endif

include mk/grafana.mk
include mk/test.mk
include mk/deploy.mk

.PHONY: project_deploy
project_deploy: 
	terraform_auto_approve=-auto-approve $(MAKE) terraform_apply
	$(MAKE) provide_athene2_content restore_dashboards

.PHONY: project_launch
# launch grafana 
project_launch:
	xdg-open $(grafana_host)/login 2>/dev/null >/dev/null &

include mk/tools.mk
