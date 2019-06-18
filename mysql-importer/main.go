package main

import (
	"fmt"
	"os"

	_ "github.com/go-sql-driver/mysql"
	_ "github.com/lib/pq"
	"github.com/urfave/cli"
)

//Version the import version
var Version = "1.0.0"

//Revision the git revision of the source code
var Revision string

var log *logType

var importerConfigPath string
var app *cli.App
var shutdown = make(chan bool)
var logFile *os.File

func main() {
	app = cli.NewApp()
	initCliParser()
	err := app.Run(os.Args)
	if err != nil {
		if log == nil {
			fmt.Printf("%s\n", err.Error())
			os.Exit(1)
		}
		fatal(err)
	}
}

func fatal(err error) {
	log.Logger.Fatal().Msg(err.Error())
	os.Exit(1)
}
