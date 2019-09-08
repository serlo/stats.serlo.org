#
# Targets concerning the gcloud
#

GCLOUD_PROJECT := serlo-dev

define GCLOUD_IS_LOGGED_OUT
	gcloud auth list 2>&1 | grep "No credentialed accounts." > /dev/null
endef

.PHONY: gcloud_login
# Logs in into gcloud
gcloud_login:
	if $(GCLOUD_IS_LOGGED_OUT); then gcloud auth login; fi
	gcloud config set project $(GCLOUD_PROJECT)

.PHONY: gcloud_logout
# logs out from gcloud
gcloud_logout:
	if ! $(GCLOUD_IS_LOGGED_OUT) ; then gcloud auth revoke; fi
