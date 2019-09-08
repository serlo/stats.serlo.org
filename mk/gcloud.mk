#
# Targets concerning the gcloud
#

define GCLOUD_IS_LOGGED_OUT
	gcloud auth list 2>&1 | grep "No credentialed accounts." > /dev/null
endef

.PHONY: gcloud_logout
# logs out from gcloud
gcloud_logout:
	if ! $(GCLOUD_IS_LOGGED_OUT) ; then gcloud auth revoke; fi
