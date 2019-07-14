#
# Set up a minikube environment for local development.
# This makefile should be kept project-independent.
#
# Run minikube_start to set up and start the minikube cluster.
# Run dnsmasq_setup once as root to setup dns resolving through dnsmasq.
#

ifeq ($(OS),Windows_NT)
	virtualizer ?= =hyperv
# we assume KVM on other systems
else
	ifeq ($(shell uname),Linux)
		vboxmanage_found := $(shell which vboxmanage)
		ifeq ($(vboxmanage_found),/usr/bin/vboxmanage)
			virtualizer ?= virtualbox
		else
			virtualizer ?= kvm2
		endif
	else
		virtualizer ?= virtualbox
	endif
endif

$(info Using virtualizer: $(virtualizer))

export env_name = minikube

minikube_mem ?= 3072
minikube_cpus ?= 2
minikube_disksize ?= 15GB
minikube_args ?= --memory $(minikube_mem) --disk-size=$(minikube_disksize) --cpus=$(minikube_cpus) --vm-driver=$(virtualizer)


bold=$(shell tput bold)
normal=$(shell tput sgr0)

ifeq ($(virtualizer),virtualbox) 
.PHONY: check_prerequisistes_linux
check_prerequisites_linux:
	@$(call check_dependency,dockerd)
	@$(call check_dependency,minikube)
	@$(call check_dependency,jq)
	@$(call check_dependency,curl)
	@$(call check_dependency,kubectl)
	@$(call check_dependency,tput)

.PHONY: check_prerequisites_linux_running
check_prerequisites_linux_running: check_prerequisites_linux
	docker ps >/dev/null

else
# check prerequisites for kvm
.PHONY: check_prerequisites_linux
check_prerequisites_linux:
	@$(call check_dependency,libvirtd)
	@$(call check_dependency,dockerd)
	@$(call check_dependency,dnsmasq)
	@$(call check_dependency,qemu-io)
	@$(call check_dependency,minikube)
	@# ebtables and bridge-utils are needed for network setup
	@$(call check_dependency,ebtables)
	@$(call check_dependency,brctl)
	@# various utilities
	@$(call check_dependency,gsutil)
	@$(call check_dependency,jq)
	@$(call check_dependency,curl)
	@$(call check_dependency,kubectl)
	@$(call check_dependency,tput)

# check the prerequisites for running minikube
.PHONY: check_prerequisites_linux_running
check_prerequisites_linux_running: check_prerequisites_linux
	systemctl status docker --no-pager
	systemctl status dnsmasq --no-pager
	systemctl status libvirtd --no-pager
endif


# check if the network is set up properly
.PHONY: minikube_check_network
minikube_check_network:
	#use any hostname for serlo.local domain
	@ping -c 1 test.serlo.local || (echo "$(bold)could not reach serlo.local! Please check your DNS configuration!$(normal)" && exit 1)

.PHONY: minikube_create
# create a new minikube cluster
minikube_create:
	minikube start $(minikube_args)
ifeq ($(virtualizer),virtualbox)
	minikube stop
	vboxmanage modifyvm "minikube" --macaddress2 "08002781A001" 2>/dev/null || true
	minikube start
endif
	minikube addons enable ingress
	minikube addons enable dashboard
	minikube addons enable freshpod
	kubectl config use-context minikube
	@echo "$(bold)Minikube was successfully created with ip $(shell minikube ip)!$(normal)"

.PHONY: minikube_start
# start an existing minikube
minikube_start:
ifneq ($(OS),Windows_NT)
	uname -s | grep Linux && $(MAKE) check_prerequisites_linux_running || true
endif
	minikube start
	kubectl config use-context minikube
	$(MAKE) minikube_check_network
	@echo "$(bold)Minikube was successfully started with ip $(shell minikube ip)!$(normal)"

.PHONY: minikube_stop
# stop the minikube cluster
minikube_stop:
	minikube stop

.PHONY: minikube_delete
# delete the minikube cluster
minikube_delete:
	minikube delete

.PHONY: minikube_dashboard
# launch minikube dashboard
minikube_dashboard:
	minikube dashboard 2>/dev/null >/dev/null &

.PHONY:
# set kubectl context
kubectl_use_context:
	kubectl config use-context minikube

.NOTPARALLEL:
