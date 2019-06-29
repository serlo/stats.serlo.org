package main

import (
	"database/sql"
	"github.com/lib/pq"
	"time"
	"fmt"
)

type eventLogTable struct {
	SourceDB *sql.DB
	TargetDB *sql.DB
	Name     string
	ResultSet []mysqlEventLog
}

// any reason we cannot join event_log and event?
type mysqlEventLog struct {
	ID      int
	ActorID int
	EventID int
	UUIDID  int
	Date    time.Time
}

func (t *eventLogTable) load(rowLimit int) (int, error) {
	maxID, err := getMaxID(t.TargetDB, t.Name)
	if err != nil {
		return 0, err
	}

	log.Logger.Info().Msgf("load [%s] max id [%d]", t.Name, maxID)
	
	rows, err := t.SourceDB.Query("SELECT id, actor_id, event_id, uuid_id, date FROM event_log WHERE id > ? ORDER BY id DESC LIMIT ?", maxID, rowLimit)
	if err != nil {
		log.Logger.Error().Msgf("cannot select %s [%s]", t.Name, err.Error())
		return 0, err
	}
	defer rows.Close()


	t.ResultSet = make([]mysqlEventLog, 0)
	count := 0
	for rows.Next() {
		data := mysqlEventLog{}
		count++
		err = rows.Scan(&data.ID, &data.ActorID, &data.EventID, &data.UUIDID, &data.Date)
		if err != nil {
			return 0, fmt.Errorf("select %s table error [%s]", t.Name, err.Error())
		}
		t.ResultSet = append(t.ResultSet, data)
	}

	log.Logger.Info().Msgf("load %s [%d] records imported\n", t.Name, count)
	return count, nil
}

func (t *eventLogTable) save() error {
	tx, err := t.TargetDB.Begin()
	if err != nil {
		return err
	}

	stmt, err := tx.Prepare(pq.CopyIn(t.Name, "id", "actor_id", "event_id", "date", "uuid_id"))
	if err != nil {
		return err
	}
	for _, data := range t.ResultSet {
		_, err := stmt.Exec(data.ID, data.ActorID, data.EventID, data.Date, data.UUIDID)
		if err != nil {
			return err
		}
	}

	_, err = stmt.Exec()
	if err != nil {
		return err
	}

	err = stmt.Close()
	if err != nil {
		return err
	}

	tx.Commit()

	// release resultSet
	t.ResultSet= []mysqlEventLog{}
	return nil
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
