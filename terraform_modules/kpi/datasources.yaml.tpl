apiVersion: 1

datasources:
- name: serlo-athene2-mysql
  type: mysql
  url: ${athene2_database_host}:3306
  database: serlo
  user: ${athene2_database_username}
  secureJsonData:
    password: "${athene2_database_password}"
- name: serlo-kpi-postgres
  type: postgres
  url: ${kpi_database_host}:5432
  database: ${kpi_database_name}
  user: ${kpi_database_username}
  secureJsonData:
    password: "${kpi_database_password}"
  jsonData:
    sslmode: "disable"


