package main

import (
	"database/sql"
	"time"
)

func runOnceImporter() error {
	log.Logger.Info().Msgf("run importer")
	config, err := readImporterConfig()
	if err != nil {
		return err
	}

	log.Logger.Info().Msgf("open athene2 database")
	var athene2DB *sql.DB
	for i := 0; i < 10; i++ {
		athene2DB, err = openAthene2DB(&config.Mysql)
		if err != nil {
			log.Logger.Error().Msgf("run importer failed to open athene2 db [%s]", err.Error())
			log.Logger.Info().Msgf("retrying in 30 seconds")
			time.Sleep(time.Second * 30)
			continue
		}
		break
	}
	if err != nil {
		// out of retries
		return err
	}

	defer athene2DB.Close()

	log.Logger.Info().Msgf("open kpi database")
	var kpiDB *sql.DB
	for i := 0; i < 10; i++ {
		kpiDB, err = openKPIDatabase(&config.Postgres)
		if err != nil {
			log.Logger.Error().Msgf("run importer failed to open kpi db [%s]", err.Error())
			log.Logger.Info().Msgf("retrying in 30 seconds")
			time.Sleep(time.Second * 30)
			continue
		}
		break
	}
	if err != nil {
		// out of retries
		return err
	}
	defer kpiDB.Close()
	
	for i := 0; i < 10; i++ {
		err = importTables(athene2DB, kpiDB)
		if err != nil {
			log.Logger.Error().Msgf("import failed [%s]", err.Error())
			log.Logger.Info().Msgf("retrying in 30 seconds")
			time.Sleep(time.Second * 30)
			continue
		}
		break
	}
	if err != nil {
		// out of retries
		return err
	}
	log.Logger.Info().Msgf("import successful")

	return nil
}

func importTables(athene2DB *sql.DB, kpiDB *sql.DB) error {
	rowLimit := 10000

	log.Logger.Info().Msgf("start importing tables")
	tables := []table{
		&uuidTable{SourceDB: athene2DB, TargetDB: kpiDB, Name: "uuid"},
		&metadataTable{SourceDB: athene2DB, TargetDB: kpiDB, Name: "metadata"},
		&userTable{SourceDB: athene2DB, TargetDB: kpiDB, Name: "user"},
		&eventTable{SourceDB: athene2DB, TargetDB: kpiDB, Name: "event"},
		&eventLogTable{SourceDB: athene2DB, TargetDB: kpiDB, Name: "event_log"},
	}
	for _, t := range tables {
		err := t.create()
		if err != nil {
			return err
		}

		for {
			rowCount, err := t.load(rowLimit)
			if err != nil {
				return err
			}
			err = t.save()
			if err != nil {
				return err
			}
			if rowCount != rowLimit {
				break
			}
		}
	}
	return nil
}
