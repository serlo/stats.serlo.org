package main

import (
	"database/sql"
	"fmt"
	"github.com/lib/pq"
)

type eventTable struct {
	SourceDB *sql.DB
	TargetDB *sql.DB
	Name     string
	ResultSet []mysqlEvent
}

// any reason we cannot join event_log and event?
type mysqlEvent struct {
	ID   int
	Name string
}

func (t *eventTable) load(rowLimit int) (int, error) {
	maxID, err := getMaxID(t.TargetDB, t.Name)
	if err != nil {
		return 0, err
	}
	log.Logger.Info().Msgf("load [%s] max id [%d]", t.Name, maxID)
	rows, err := t.SourceDB.Query("SELECT id, name FROM event WHERE id > ? LIMIT ?", maxID, rowLimit)
	if err != nil {
		log.Logger.Error().Msgf("cannot select %s [%s]", t.Name, err.Error())
		return 0, err
	}
	defer rows.Close()

	t.ResultSet = make([]mysqlEvent, 0)
	count := 0
	for rows.Next() {
		data := mysqlEvent{}
		count++
		err = rows.Scan(&data.ID, &data.Name)
		if err != nil {
			return 0, fmt.Errorf("select %s table error [%s]", t.Name, err.Error())
		}
		t.ResultSet = append(t.ResultSet, data)
	}

	log.Logger.Info().Msgf("load %s [%d] records imported", t.Name, count)
	return count, nil
}

func (t *eventTable) save() error {
	tx, err := t.TargetDB.Begin()
	if err != nil {
		return err
	}

	stmt, err := tx.Prepare(pq.CopyIn(t.Name, "id", "name"))
	if err != nil {
		return err
	}
	for _, data := range t.ResultSet {
		_, err := stmt.Exec(&data.ID, &data.Name)
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
	t.ResultSet= []mysqlEvent{}
	return nil
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
