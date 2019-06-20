# Athene2 KPI Importer

The importer is a Golang application that loads data from athen2 database and inserts it into the KPI database.

The importer will run periodically using cron in a docker image.

The application takes no command line arguments. It expects a config.yaml in the working directgory that configures some settings. A sample config is given below

```yaml
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
