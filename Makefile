#
# Makefile for local development for the serlo KPI project.
#

.PHONY: _help
# print help as the default target. 
# since hte actual help recipe is quite long, it is moved
# to the bottom of this makefile.
_help: help

infrastructure_repository ?= ../infrastructure

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


.PHONY: help
# print a list of goals
help:
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-0-9\%/][a-zA-Z\-\_0-9\%/\.]*:/ { \
		helpMessage = match(lastLine, /^# (.*)/); \
		if (helpMessage) { \
			helpMessage = substr(lastLine, RSTART + 2, RLENGTH); \
		} else { \
			helpMessage = "<not documented>"; \
		} \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			if (match(helpCommand, /[\%]/)) {
				helpCommand = "$(DIM)"helpCommand;
			}
			printf "    ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 } \
	FNR==1 { \
		printf "\n $(WHITE)%s$(RESET):\n", FILENAME; \
		header=1; \
	} \
	/^#/ { \
		if (header) { \
			match($$0, /^# (.*)/);
			documentation = substr($$0, RSTART + 2, RLENGTH); \
			if (documentation) { \
				printf "  "documentation"\n"; \
			} \
		} \
	} \
	/^[^#]/ { header=0; } \
	/^$$/ { header=0; } \
	\
	' $(MAKEFILE_LIST)

# COLORS
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)
DIM  := $(shell tput -Txterm dim)
