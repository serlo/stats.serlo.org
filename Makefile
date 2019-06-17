#
# Makefile for local development for the serlo KPI project.
# 


infrastructure_repository ?= ../infrastructure/

include mk/grafana.mk
include mk/test.mk
include mk/deploy.mk

.PHONY: deploy
deploy: terraform_apply provide_athene2_content restore_dashboards

include mk/dev.mk
