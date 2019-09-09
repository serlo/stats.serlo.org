#
# Targets for the KPI project
#

GCLOUD_PROJECT := serlo-dev

define GCLOUD_IS_LOGGED_OUT
	gcloud auth list 2>&1 | grep "No credentialed accounts." > /dev/null
endef

.PHONY: project_start
# create a project minikube cluster and deploy the project resources, all in
# one target.
project_start: minikube_start build_local docker_minikube_setup project_deploy \
	minikube_launch

.PHONY: project_deploy
# deploy the project to an already running cluster
project_deploy: terraform_init terraform_apply

.PHONY: project_smoketest
# run smoketest for kpi project
project_smoketest: kubectl_use_context
	$(MAKE) -C smoketest

.PHONY: gcloud_login
# Logs in into gcloud
gcloud_login:
	if $(GCLOUD_IS_LOGGED_OUT); then gcloud auth login; fi
	gcloud config set project $(GCLOUD_PROJECT)

.PHONY: gcloud_logout
# logs out from gcloud
gcloud_logout:
	if ! $(GCLOUD_IS_LOGGED_OUT) ; then gcloud auth revoke; fi

.PHONY: provide_athene2_content
# upload the current database dump to the content provider container
provide_athene2_content: gcloud_login kubectl_use_context
	scripts/setup-athene2-db.sh
