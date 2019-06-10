# Data Analysis and KPI Monitoring

Repository contains the current grafana dashboard sources used to develop the KPI project as well as future scripts which are required to setup the mysql importer or other functionality.

## Getting Started

The KPI local project can be setup using infrastructure repository live/dev-kpi-local environment.

The Makefile in this repository will support the upload of the current dashboards to the local environment and later also to the staging and production environment.

## Backup and Restore

After creating a local minikube kpi deployment you need to use ```make dashb-restore``` to upload the current dashboards in dashbords folder.

After the changes are done and you want to save them you need to run ```make dashb-backup``` to export the dashboards and save them in the dashboards folder.

Please note the backup and upload does not use the import and export format but the Grafana API which uses a different format.

## Development

Proposed development life cycle for KPI project:

- development branch contains the dashboards which are under development
- master branch contains the dashboards which are deployed to staging and production.

How to automatically upload the dashboards to staging and production still needs to be discussed.
