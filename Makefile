#
# Makefile for local development for the serlo KPI project.
#

### Environment ###

# the environment type. use minikube for development
env_name ?=
# path to the serlo infrastructure repository
infrastructure_repository ?= ../infrastructure


.PHONY: _help
# print help as the default target. 
# since hte actual help recipe is quite long, it is moved
# to the bottom of this makefile.
_help: help

ifeq ($(env_name),minikube)
include mk/minikube.mk
export terraform_auto_approve=-auto-approve
else
    ifeq ($(env_name),dev)
    	include mk/gcloud.mk
    	#no auto approve in gcloud dev environment
    	export terraform_auto_approve=
    else
        ifneq ($(subst help,,$(MAKECMDGOALS)),)
    		$(error only env_name [minikube,dev] are supported)
        endif
    endif
endif

include mk/help.mk
include mk/grafana.mk
include mk/test.mk
include mk/deploy.mk
include mk/tools.mk

# forbid parallel building of prerequisites
.NOTPARALLEL:


.PHONY: project_deploy
# deploy the project to an already running cluster
project_deploy: terraform_apply provide_athene2_content restore_dashboards


.PHONY: project_launch
# launch the grafana dashboard
project_launch:
	xdg-open $(grafana_host)/login 2>/dev/null >/dev/null &

# COLORS
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
BLUE   := $(shell tput -Txterm setaf 4)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)
DIM  := $(shell tput -Txterm dim)
