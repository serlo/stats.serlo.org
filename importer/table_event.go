package main

import (
	"database/sql"
)

type eventTable struct {
	SourceDB *sql.DB
	TargetDB *sql.DB
	Name     string
}

// any reason we cannot join event_log and event?
type mysqlEvent struct {
	ID   int
	Name string
}

func (t *eventTable) insertData(data *mysqlEvent) func() []interface{} {
	return func() []interface{} {
		return []interface{}{
			(*data).ID, (*data).Name}
	}
}

func (t *eventTable) load() error {
	data := mysqlEvent{}
	return loadTable(t.SourceDB,
		t.TargetDB,
		t.Name,
		"SELECT id, name FROM event WHERE id > ?",
		[]interface{}{&data.ID, &data.Name},
		"INSERT INTO public.event (id, name) VALUES ($1, $2);",
		t.insertData(&data))
}

func (t *eventTable) create() error {
	stmts := []string{`CREATE TABLE public.event (
				id int8 NOT NULL CONSTRAINT event_primary_key PRIMARY KEY,
				name varchar(255) NOT NULL
				);`,
		`CREATE INDEX event_name ON public.event USING btree (name);`,
	}
	return createTable(t.TargetDB, t.Name, stmts)
}
