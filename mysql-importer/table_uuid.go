package main

import (
	"database/sql"
)

type uuidTable struct {
	SourceDB *sql.DB
	TargetDB *sql.DB
	Name     string
}

// any reason we cannot join event_log and event?
type mysqlUUID struct {
	ID            int
	Discriminator string
}

func (t *uuidTable) insertData(data *mysqlUUID) func() []interface{} {
	return func() []interface{} {
		return []interface{}{
			(*data).ID, (*data).Discriminator}
	}
}

func (t *uuidTable) load() error {
	data := mysqlUUID{}
	return loadTable(t.SourceDB,
		t.TargetDB,
		t.Name,
		"SELECT id, discriminator FROM uuid WHERE id > ?",
		[]interface{}{&data.ID, &data.Discriminator},
		"INSERT INTO public.uuid (id, discriminator) VALUES ($1, $2);",
		t.insertData(&data))
}

func (t *uuidTable) create() error {
	stmts := []string{`CREATE TABLE public.uuid (
				id int8 NOT NULL CONSTRAINT uuid_primary_key PRIMARY KEY,
				discriminator varchar(45) NOT NULL
				);`,
		`CREATE INDEX uuid_discriminator ON public.uuid USING btree (discriminator);`,
	}
	return createTable(t.TargetDB, t.Name, stmts)
}
