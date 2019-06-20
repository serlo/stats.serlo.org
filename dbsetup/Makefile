image="athene2-dbsetup-cronjob"

#every hour check if database is empty after initial check
cron_pattern=0 0/1 * * *

.PHONY: docker-build
docker-build:
	docker build --build-arg git_revision=$(shell git log | head -n 1 | cut  -f 2 -d ' ') --build-arg cron_pattern="$(cron_pattern)" -t serlo/$(image) .

.PHONY: docker-push
docker-push:
	docker tag serlo/$(image):latest eu.gcr.io/serlo-containers/$(image):latest
	docker push eu.gcr.io/serlo-containers/$(image):latest
