package main

import (
	"os"
	"strings"

	"github.com/rs/zerolog"
)

type logType struct {
	Logger zerolog.Logger
	File   *os.File
	Config loggingConfig
}

func (l *logType) close() {
	if l.File != nil {
		l.File.Close()
	}
}

func newLogger(config loggingConfig) *logType {
	return &logType{Config: config}
}

func (l *logType) init() error {
	var level zerolog.Level
	configLevel := strings.ToLower(l.Config.Level)
	switch configLevel {
	case "info":
		level = zerolog.InfoLevel
	case "warn":
		level = zerolog.WarnLevel
	case "error":
		level = zerolog.ErrorLevel
	case "debug":
		level = zerolog.DebugLevel
	default:
		level = zerolog.InfoLevel
	}

	zerolog.SetGlobalLevel(level)

	l.Logger = zerolog.New(os.Stdout).With().Timestamp().Logger()
	if l.File != nil {
		l.close()
	}
	if l.Config.File != "" {
		var err error
		logFile, err = os.Create(l.Config.File)
		if err != nil {
			return err
		}
		log.Logger = log.Logger.Output(zerolog.SyncWriter(logFile))
	}
	return nil
}
