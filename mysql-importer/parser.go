package main

import (
	"fmt"
	"sort"
	"time"

	"github.com/urfave/cli"
)

func initCliParser() {
	app.Version = Version

	app.Commands = []cli.Command{
		cli.Command{
			Name:        "revision",
			Action:      revisionCommand,
			Description: "show the git revision",
		},
		cli.Command{
			Name:        "run",
			Action:      runCommand,
			Description: "run periodically importer as configured in config file",
			Flags: []cli.Flag{
				cli.StringFlag{
					Name:  "config",
					Value: "config.yaml",
					Usage: "load configuration from `FILE`",
				},
			},
		},
		cli.Command{
			Name:        "once",
			Action:      runOnceCommand,
			Description: "run importer only once",
			Flags: []cli.Flag{
				cli.StringFlag{
					Name:  "config",
					Value: "config.yaml",
					Usage: "load configuration from `FILE`",
				},
			},
		},
		cli.Command{
			Name: "revision",
			Action: func(c *cli.Context) error {
				log.Logger.Info().Msgf("revison [%s]", Revision)
				return nil
			},
			Description: "get revision of cli",
		},
	}

	sort.Sort(cli.FlagsByName(app.Flags))
	sort.Sort(cli.CommandsByName(app.Commands))
}

func runCommand(c *cli.Context) error {
	importerConfigPath = c.String("config")

	err := setup()
	if err != nil {
		return err
	}
	config, err := readImporterConfig()
	if err != nil {
		return fmt.Errorf("config error [%s]", err.Error())
	}

	time.Sleep(time.Second * time.Duration(config.Scheduler.DelayTimeInSec))

	runImporter(config.Scheduler.IntervalInMin)

	<-shutdown

	log.Logger.Info().Msg("shutdown in run mode")

	return nil
}

func runOnceCommand(c *cli.Context) error {
	importerConfigPath = c.String("config")

	err := setup()
	if err != nil {
		return err
	}
	config, err := readImporterConfig()
	if err != nil {
		return fmt.Errorf("config error [%s]", err.Error())
	}

	time.Sleep(time.Second * time.Duration(config.Scheduler.DelayTimeInSec))

	runOnceImporter()

	return nil
}

func revisionCommand(c *cli.Context) error {
	fmt.Printf("%s\n", Revision)
	return nil
}

func setup() error {
	config, err := readImporterConfig()
	if err != nil {
		return fmt.Errorf("config error [%s]", err.Error())
	}

	log = newLogger(config.Logging)
	err = log.init()
	if err != nil {
		return err
	}

	return nil
}
