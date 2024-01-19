# Obscolescence Notice: stats.serlo.org
Serlo statistics are now moved to Jupyter notebooks in https://github.com/serlo/evaluations, making this repository obsolete.

# Data Analysis and KPI Monitoring

Repository contains the current grafana dashboard sources used to develop the KPI project as well as future scripts which are required to setup the mysql importer or other functionality.

## Getting Started

If you want to setup a local KPI project environment you currently have to use minikube with the `kvm2` driver.

To run the minikube cluster check the Prerequisite section which depends on the OS and the virtualizer.

We use a project makefile to simplify the tasks like building the project images or creating a project cluster.
If you want to setup a new (minikube) project cluster the following make call will be helpful:

```make minikube_delete project_start```

In case you already have a cluster and just restarted your machine.

```make project_start```

In case you already want to change dashboards, update the dashboard JSON files in `container/grafana/dashboards/` and re-build the local docker conainers by running:

```make build_local```

Infrastructure changes (terraform scripts) can be re-deployed by running:

```make project_deploy```

## Prerequisites

Currently only (MacOS) and Linux as OS are supported and KVM as virtualizer.
To set up the necessary DNS entries, run `make minikube_dns` after the minikube cluster has been created and add the printed line to /etc/hosts.

## Project Make

The KPI project follows a project pattern implemented with Make.
Building, deployment and also testing can be controlled using make goals.

The most important targets are explained in the *Getting Started*-section.
Various helpers, tools and internal goals are available as well, typing

```make help``` 

will provide you with an overview of those, as well as with an up-to-date description.

## Dashboard Backup and Restore

Since dashboards are provisioned with the grafana container, they cannot be saved via the web interface. Instead, they have to be downloaded in JSON format and saved in `container/grafana/dashboards`.

To deploy new dashboards, simply re-build the grafana container (either directly or through `make build_local`).

### MYSQL Importer

See README.md in mysql-importer folder.
