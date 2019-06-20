package main

import (
	"fmt"
	"os"

	_ "github.com/go-sql-driver/mysql"
	_ "github.com/lib/pq"
)

//Version the import version
var Version = "1.0.0"

//Revision the git revision of the source code
var Revision string

var log *logType

var importerConfigPath string
var shutdown = make(chan bool)
var logFile *os.File

func main() {
	importerConfigPath = "config.yaml"
	config, err := readImporterConfig()
	if err != nil {
		fmt.Printf("cannot find config.yaml file [%s]", err.Error())
		os.Exit(1)
	}

	log = newLogger(config.Logging)
	err = log.init()
	if err != nil {
		fmt.Printf("cannot inialize logger")
		os.Exit(1)
	}

	runOnceImporter()
}