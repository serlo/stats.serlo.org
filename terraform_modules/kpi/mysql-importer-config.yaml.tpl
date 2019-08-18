Logging:
        Level: ${mysql_importer_log_level}

Mysql:
        Url: ${athene2_db_host}:3306
        User: ${athene2_db_user}
        Password: ${athene2_db_password}
        DBName: ${athene2_db_name}

Postgres:
        Host: ${kpi_database_host}
        Port: ${kpi_database_port}
        User: ${kpi_database_username}
        Password: ${kpi_database_password}
        DBName: ${kpi_database_name}
        SSLMode: disable
