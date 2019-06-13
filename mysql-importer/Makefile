.PHONY: build
build:
	go build

.PHONY: run-once
run-once:
	go run *.go -- once

.PHONY: run-interval
run-interval:
	go run *.go -- run


.PHONY: docker-build
docker-build:
	docker build -t serlo/kpi-mysql-importer .

.PHONY: docker-push
docker-push:
	docker tag serlo/kpi-mysql-importer:latest eu.gcr.io/seryylo-containers/kpi-mysql-importer:latest
	docker push eu.gcr.io/serlo-containers/kpi-mysql-importer:latest

.PHONY: docker-run
docker-run:
	docker run --network=host -v $(CURDIR)/config.yaml:/app/config.yaml --rm serlo/kpi-importer -- once
