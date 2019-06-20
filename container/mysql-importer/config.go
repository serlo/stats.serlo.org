package main

import (
	"fmt"
	"io/ioutil"

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

type importerConfig struct {
	Logging   loggingConfig   `yaml:"Logging"`
	Mysql     mysqlConfig     `yaml:"Mysql"`
	Postgres  postgresConfig  `yaml:"Postgres"`
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

	return config, err
}