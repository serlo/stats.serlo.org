# Data Analysis and KPI Monitoring

Repository contains the current grafana dashboard sources used to develop the KPI project as well as future scripts which are required to setup the mysql importer or other functionality.

## Getting Started

If you want to setup a local KPI project environment set the environment variable ```env_name=minikube```.

To run the minikube cluster check the Prerequisite section which depends on the OS and the virtualizer.

We use a project make to simplify the tasks like building the project images or creating a project cluster.
If you want to setup a new project cluster the following make call will be helpful:

```make project_delete project_create project_deploy project_launch```

The will delete an existing cluster, create a new cluster, upload the dashboards and provision the test database and finally launches  grafana UI in the web browser.

## Prerequisites

Currently only MacOS and Linux as OS are supported and KVM and Virtualbox as virtualizer.
Two make the cluster behave as if it is deployed in some domain you also may need dnsmasq setup.

FIXME add more instructions for setup or refer to a common documentation

## Project Make

The KPI project follows a project pattern implemented with Make.
Building, deployment and also testing can be controlled using make goals.

The environment in which the make operates can be set using the env variable env_name.

```env_name=minikube``` will operate with a local minikube cluster.
```env_name=dev``` will operate with the google cloud dev environment.

Goals follow some naming conventions.

All goals starting with ```project``` are usually standardized accross projects.

```project_create``` creates the environment in case of minikube in dev it will have no effect.

```project_delete``` deletes the environment but has only an effect in minikube environment.

```project_start```  starts the cluster but has only an effect in minikube environment.

```project_deploy``` provisions the project into the kubernetes cluster

```project_launch``` starts the browser with the project start page if it exists

```project_smoketest``` runs a short smoketest to verify if the project is working properly

All goals starting with ```tools``` provide some helper to debug or change some pods and are project specific.

All goals starting with ```build``` take care of building images in the project repository.

```build_images``` only builds them if they are not already in the minikube cluster.

```build_images_forced``` forces a re-build of the images and pushes them to the minikube cluster.

All goals starting with ```terraform```  handle the terraform provisioning

The KPI project depends on the infrastructure repository and it is recommended to keep both repositories in the same workspace folder level.

## Dashboard Backup and Restore

After selecting the environment you can upload the dashboard with ```make restore_dashboards```.

After changes in Grafana you can save them with ```make backup_dashboards``` to the dashboards folder.

Please note the backup and upload does not use the import and export format but the Grafana API which uses a different format.

## Build

KPI project has currently two images that are build using make ```build_images```.

### MYSQL Importer

The importer is a Golang application that loads data from mysql and inserts it into postgresql.

The importer will run periodically or once.

```importer run``` runs the interval mode
```importer once``` runs the once mode

importer requires a config.yaml file that configures some settings. A sample config is given below

```yaml
Scheduler:
        IntervalInMin: 10

Logging:
        Level: info

Mysql:
        Host: mysql.serlo.local:30020
        User: root
        Password: admin
        DBName: serlo
Postgres:
        Host: postgres.serlo.local
        Port: 30021
        User: postgres
        Password: admin
        DBName: kpi
        SSLMode: disable
```
