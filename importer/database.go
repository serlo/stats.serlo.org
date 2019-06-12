package main

import (
	"database/sql"
	"fmt"
	"os"
	"regexp"
)

type table interface {
	create() error
	load() error
}

func openSourceDB(config *mysqlConfig) *sql.DB {
	mysqlInfo := fmt.Sprintf("%s:%s@tcp(%s)/serlo?parseTime=true", config.User, config.Password, config.Host)
	db, err := sql.Open("mysql", mysqlInfo)

	if err != nil {
		log.Logger.Error().Msgf("cannot open source database [%s]\n", err.Error())
		os.Exit(1)
	}
	return db
}

func openKPIDatabase(config *postgresConfig) *sql.DB {
	psqlInfo := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		config.Host, config.Port, config.User, config.Password, config.DBName, config.SSLMode)
		
	db, err := sql.Open("postgres", psqlInfo)
	err = db.Ping()

	if err != nil  {
		match, err := regexp.MatchString(".*database.*does not exist", err.Error())
		if err != nil {
			log.Logger.Error().Msgf("open kpi database error in match [%s]\n", err.Error())
			os.Exit(1)
		}
		if match {
			log.Logger.Info().Msgf("create %s database", config.DBName)
			createKPIDatabase(config)
			db, err = sql.Open("postgres", psqlInfo)
			if err != nil  {
				log.Logger.Error().Msgf("cannot open %s database after creating it [%s]", config.DBName, err.Error())
				os.Exit(1)
			}
			return db
		}
		log.Logger.Error().Msgf("cannot open %s database [%s]\n", config.DBName, err.Error())
		os.Exit(1)
	}

	log.Logger.Info().Msgf("open %s database successful", config.DBName)

	return db
}

func createKPIDatabase(config *postgresConfig) {
	psqlInfo := fmt.Sprintf("host=%s port=%d user=%s password=%s sslmode=%s",
		config.Host, config.Port, config.User, config.Password, config.SSLMode)
	db, err := sql.Open("postgres", psqlInfo)

	if err != nil {
		log.Logger.Error().Msgf("cannot open kpi database server [%s]\n", err.Error())
		os.Exit(1)
	}

	_, err = db.Exec("CREATE DATABASE kpi")
	if err != nil {
		log.Logger.Error().Msgf("cannot create kpi database [%s]\n", err.Error())
	}
}



func isTableCreated(targetDB *sql.DB, name string) (bool, error) {
	stmt := fmt.Sprintf(`SELECT EXISTS (
		SELECT 1
		FROM   information_schema.tables 
		WHERE  table_schema = 'public'
		AND    table_name = '%s'
		)`, name)
	row := targetDB.QueryRow(stmt)
	result := false
	err := row.Scan(&result)
	if err != nil {
		return false, err
	}
	return result, nil
}

func getMaxID(targetDB *sql.DB, name string) (int, error) {
	row := targetDB.QueryRow(fmt.Sprintf("SELECT id FROM public.%s WHERE id=(SELECT max(id) FROM public.%s)", name, name))
	var id int
	switch err := row.Scan(&id); err {
	case sql.ErrNoRows:
		return 0, nil
	case nil:
		return id, nil
	default:
		return -1, fmt.Errorf("cannot get max id from table %s [%s]", name, err.Error())
	}
}

func createTable(db *sql.DB, name string, statements []string) error {
	created, err := isTableCreated(db, name)
	if err != nil {
		return err
	}
	if !created {
		log.Logger.Info().Msgf("'create %s\n", name)
		for _, stmt := range statements {
			_, err := db.Exec(stmt)
			if err != nil {
				return fmt.Errorf("create table %s failed [%s]", name, err.Error())
			}
		}
	}

	return nil
}

func loadTable(sourceDB *sql.DB, targetDB *sql.DB, name string, selectStmt string, selectData []interface{}, insertStmt string, insertData func() []interface{}) error {
	maxID, err := getMaxID(targetDB, name)
	if err != nil {
		return err
	}
	rows, err := sourceDB.Query(selectStmt, maxID)
	if err != nil {
		log.Logger.Error().Msgf("cannot select %s [%s]", name, err.Error())
		return err
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		count++
		err = rows.Scan(selectData...)
		if err != nil {
			return fmt.Errorf("select %s table error [%s]", name, err.Error())
		}
		_, err = targetDB.Exec(insertStmt, insertData()...)
		if err != nil {
			return fmt.Errorf("insert %s table error [%s]", name, err.Error())
		}
	}

	log.Logger.Info().Msgf("load %s [%d] records imported\n", name, count)
	return nil
}
