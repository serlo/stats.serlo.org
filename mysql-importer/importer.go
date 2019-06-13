package main

import (
	"time"
)

func runImporter(periodInMin int) {
	log.Logger.Info().Msgf("run importer in intervals of [%d] minutes", periodInMin)
	importTicker := time.NewTicker(time.Duration(periodInMin) * time.Minute)

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

func runOnceImporter() {
	config, err := readImporterConfig()
	if err != nil {
		fatal(err)
	}

	log.Logger.Info().Msgf("run importer")
	sourceDB := openSourceDB(&config.Mysql)
	defer sourceDB.Close()
	kpiDB := openKPIDatabase(&config.Postgres)
	defer kpiDB.Close()

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
			fatal(err)
		}
		err = t.load()
		if err != nil {
			fatal(err)
		}
	}
}
