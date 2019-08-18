#
# Set up a minikube environment for local development.
# This makefile should be kept project-independent.
#
# Run minikube_start to set up and start the minikube cluster.
# Run dnsmasq_setup once as root to setup dns resolving through dnsmasq.
#

# we assume KVM 
virtualizer ?= kvm2

MINIKUBE_EXISTS := $(shell virsh -c qemu:///system list --all \
					| grep "minikube" > /dev/null && echo "true" || echo "false")

# expands to $2 if $1 is true
iftrue = $(if $(subst true,,$1),,$2)
# expands to $2 if $1 is false
iffalse = $(if $(subst false,,$1),,$2)

$(info $(call iffalse,$(MINIKUBE_EXISTS),Minikube does not exist!))
$(info Using virtualizer: $(virtualizer))

export env_name = minikube

minikube_mem ?= 3072
minikube_cpus ?= 2
minikube_disksize ?= 15GB
minikube_args ?= --memory $(minikube_mem) --disk-size=$(minikube_disksize) --cpus=$(minikube_cpus) --vm-driver=$(virtualizer)


bold=$(shell tput bold)
normal=$(shell tput sgr0)

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


# check if the network is set up properly
.PHONY: minikube_check_network
minikube_check_network:
	#use any hostname for serlo.local domain
	@ping -c 1 test.serlo.local || (echo "$(bold)could not reach serlo.local! Please check your DNS configuration!$(normal)" && exit 1)

.PHONY: minikube_create
# create a new minikube cluster
minikube_create: check_prerequisites_linux_running
	minikube start $(minikube_args)
#	virt-xml -c qemu:///system minikube --edit 1 --network mac=52:54:00:67:4a:01
#	virt-xml -c qemu:///system minikube --edit 2 --network mac=52:54:00:67:4a:02
#	minikube stop
#	minikube start $(minikube_args)	
	minikube addons enable ingress
	minikube addons enable dashboard
	minikube addons enable freshpod
	@echo "$(bold)Minikube was created with ip $$(minikube ip)!$(normal)"

.PHONY: minikube_start
# start an existing minikube
minikube_start: $(call iffalse,$(MINIKUBE_EXISTS),minikube_create)
	minikube start $(minikube_args)
	kubectl config use-context minikube
	$(MAKE) minikube_check_network
	@echo "$(bold)Minikube was successfully started with ip $$(minikube ip)!$(normal)"

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

.PHONY: minikube_dns
# configure dns for minikube ip
minikube_dns:
	@echo "$(shell minikube ip 2>/dev/null)	stats.serlo.local mysql.serlo.local postgres.serlo.local test.serlo.local"

.PHONY:
# set kubectl context
kubectl_use_context:
	kubectl config use-context minikube

.NOTPARALLEL:
