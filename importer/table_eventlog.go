package main

import (
	"database/sql"
	"time"
)

type eventLogTable struct {
	SourceDB *sql.DB
	TargetDB *sql.DB
	Name     string
}

// any reason we cannot join event_log and event?
type mysqlEventLog struct {
	ID      int
	ActorID int
	EventID int
	UUIDID  int
	Date    time.Time
}

func (t *eventLogTable) insertData(data *mysqlEventLog) func() []interface{} {
	return func() []interface{} {
		return []interface{}{
			(*data).ID, (*data).ActorID, (*data).EventID, (*data).Date, (*data).UUIDID,
		}
	}
}

func (t *eventLogTable) load() error {
	data := mysqlEventLog{}
	return loadTable(t.SourceDB,
		t.TargetDB,
		t.Name,
		"select id, actor_id, event_id, date, uuid_id from event_log WHERE id > ?",
		[]interface{}{&data.ID, &data.ActorID, &data.EventID, &data.Date, &data.UUIDID},
		"INSERT INTO public.event_log (id, actor_id, event_id, date, uuid_id) VALUES ($1, $2, $3, $4, $5);",
		t.insertData(&data))
}

func (t *eventLogTable) create() error {
	stmts := []string{`CREATE TABLE public.event_log (
		id int8 NOT NULL CONSTRAINT event_log_primary_key PRIMARY KEY,
		actor_id int8 NOT NULL,
		event_id int8 NOT NULL REFERENCES event(id),
		date timestamp NOT NULL,
		uuid_id int8 NOT NULL REFERENCES uuid(id)
		);`,
		`CREATE INDEX event_log_actor_id ON public.event_log USING btree (actor_id);`,
	}
	return createTable(t.TargetDB, t.Name, stmts)
}
