package main

import (
	"database/sql"
	"time"

	"github.com/lib/pq"
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
		err = importTables(athene2DB, kpiDB, &config.Debug)
		if err != nil {
			if checkPsqlError(err) {
				log.Logger.Error().Msgf("import failed [%s, %s]", err.(*pq.Error).Code.Name(), err.Error())
				if err.(*pq.Error).Code.Name() == "foreign_key_violation" {
					log.Logger.Info().Msgf("skipping for now...")
				} else {
					log.Logger.Info().Msgf("retrying in 30 seconds")
					time.Sleep(time.Second * 30)
				}
			} else {
				log.Logger.Error().Msgf("import failed %s", err.Error())
				log.Logger.Info().Msgf("retrying in 30 seconds")
				time.Sleep(time.Second * 30)
			}
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

func importTables(athene2DB *sql.DB, kpiDB *sql.DB, dconfig *debugConfig) error {
	rowLimit := 10000

	log.Logger.Info().Bool("OnlyFirstChunk", dconfig.OnlyFirstChunk).Msgf("is set")

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

		total := 0
		update := true
		for update {
			var err error
			var targetMaxID int
			update, targetMaxID, err = checkForUpdates(athene2DB, kpiDB, t.name())
			if err != nil {
				return err
			}
			if update {
				rowCount, err := t.load(targetMaxID, rowLimit)
				if err != nil {
					return err
				}

				if rowCount > 0 {
					err = t.save()
					if err != nil {
						return err
					}
					total += rowCount
				}
			}
			if dconfig.OnlyFirstChunk {
				break
			}
		}
		if total != 0 {
			log.Logger.Info().Str("table", t.name()).Int("importedCount", total).Msgf("rows successfully imported")
		}
	}
	return nil
}

func checkPsqlError(err error) bool {
	switch err.(type) {
	case *pq.Error:
		return true
	default:
		return false
	}
}
