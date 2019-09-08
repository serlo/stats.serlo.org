#
# Makefile for local development for the serlo KPI project.
#

# location of the current serlo database dump
export dump_location ?= gs://serlo_dev_terraform/sql-dumps/dump-2019-05-13.zip

.PHONY: _help
# print help as the default target. 
# since the actual help recipe is quite long, it is moved
# to the bottom of this makefile.
_help: help

# forbid parallel building of prerequisites
.NOTPARALLEL:

include mk/utils_make.mk
include mk/help.mk
include mk/minikube.mk
include mk/terraform.mk
include mk/tools.mk
include mk/build.mk
include mk/project.mk

