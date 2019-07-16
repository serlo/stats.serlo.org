package main

import (
	"fmt"
	"io/ioutil"
    "os"
    "strconv"

	"github.com/go-yaml/yaml"
)

type loggingConfig struct {
	Level    string `yaml:"Level"`
	File     string `yaml:"File"`
	Truncate bool   `yaml:"Truncate"`
}

type mysqlConfig struct {
	URL     string `yaml:"Url"`
	User     string `yaml:"User"`
	Port 	 string `yaml:"Port"`
	Password string `yaml:"Password"`
	DBName   string `yaml:"DBName"`
}

type postgresConfig struct {
	Host     string `yaml:"Host"`
	Port     int    `yaml:"Port"`
	User     string `yaml:"User"`
	Password string `yaml:"Password"`
	DBName   string `yaml:"DBName"`
	SSLMode  string `yaml:"SSLMode"`
}

type debugConfig struct {
    // only import the first chunk of data for every table.
    OnlyFirstChunk bool `yaml:"OnlyFirstChunk"`
}

type importerConfig struct {
	Logging      loggingConfig   `yaml:"Logging"`
	Mysql        mysqlConfig     `yaml:"Mysql"`
	Postgres     postgresConfig  `yaml:"Postgres"`
    Debug        debugConfig     `yaml:"Debug"`
}

func readEnvironmentConfig(config *importerConfig) {
    name := "KPI_MYSQL_IMPORT_ONLY_FIRST_CHUNK"
    str := os.Getenv(name)
    if str != "" {
        value, err := strconv.ParseBool(str)
        if err != nil {
            log.Logger.Error().Msgf("invalid value of variable \"%s\": \"%s\"", name, str)
        } else {
            config.Debug.OnlyFirstChunk = value
        }
    }
}

func readImporterConfig() (*importerConfig, error) {
	config := &importerConfig{}
	configBytes, err := ioutil.ReadFile(importerConfigPath)
	if err != nil {
		return nil, fmt.Errorf("config error: read config=%s error=%s", importerConfigPath, err.Error())
	}
	err = yaml.Unmarshal(configBytes, &config)
	if err != nil {
		return nil, fmt.Errorf("config error: unmarshal error in puppet config=%s error=%s",
			importerConfigPath,
			err.Error())
	}
    readEnvironmentConfig(config)
	return config, err
}
