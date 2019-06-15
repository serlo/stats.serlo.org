package main

import (
	"time"
)

func runImporter(periodInMin int) {
	log.Logger.Info().Msgf("run importer scheduler in intervals of [%d] minutes", periodInMin)
	importTicker := time.NewTicker(time.Duration(periodInMin) * time.Minute)

	//start importer for the first time after that when the timer is due
	//delay run for 10 seconds
	time.Sleep(time.Second * 10)
	runOnceImporter()

	for {
		select {
		case <-importTicker.C:
			runOnceImporter()
		case <-shutdown:
			importTicker.Stop()
			log.Logger.Info().Msg("shutdown importer")
			return
		}
	}
}

func runOnceImporter() error {
	log.Logger.Info().Msgf("run importer")
	config, err := readImporterConfig()
	if err != nil {
		return err
	}

	log.Logger.Info().Msgf("open athene2 database")
	sourceDB, err := openSourceDB(&config.Mysql)
	if err != nil {
		log.Logger.Error().Msgf("run importer failed to open athene2 db [%s]", err.Error())
		return err
	}
	defer sourceDB.Close()

	log.Logger.Info().Msgf("open kpi database")
	kpiDB, err := openKPIDatabase(&config.Postgres)
	if err != nil {
		log.Logger.Error().Msgf("run importer failed to open kpi db [%s]", err.Error())
		return err
	}
	defer kpiDB.Close()

	log.Logger.Info().Msgf("start import")
	tables := []table{
		&uuidTable{SourceDB: sourceDB, TargetDB: kpiDB, Name: "uuid"},
		&metadataTable{SourceDB: sourceDB, TargetDB: kpiDB, Name: "metadata"},
		&userTable{SourceDB: sourceDB, TargetDB: kpiDB, Name: "user"},
		&eventTable{SourceDB: sourceDB, TargetDB: kpiDB, Name: "event"},
		&eventLogTable{SourceDB: sourceDB, TargetDB: kpiDB, Name: "event_log"},
	}
	for _, t := range tables {
		err := t.create()
		if err != nil {
			return err
		}
		err = t.load()
		if err != nil {
			return err
		}
	}
	return nil
}
