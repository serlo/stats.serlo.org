#
# Makefile for local development for the serlo KPI project.
# 


infrastructure_repository ?= ../infrastructure/

include mk/grafana.mk
include mk/test.mk
include mk/deploy.mk


