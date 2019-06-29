package main

import (
	"database/sql"
	"github.com/lib/pq"
	"fmt"
)

type uuidTable struct {
	SourceDB *sql.DB
	TargetDB *sql.DB
	Name     string
	ResultSet     []mysqlUUID
}

// any reason we cannot join event_log and event?
type mysqlUUID struct {
	ID            int
	Discriminator string
}

func (t *uuidTable) name() string {
	return t.Name
}

func (t *uuidTable) load(maxID int, rowLimit int) (int, error) {
	log.Logger.Info().Msgf("load [%s] id > [%d]", t.Name, maxID)

	rows, err := t.SourceDB.Query("SELECT id, discriminator FROM uuid WHERE id > ? ORDER BY id ASC LIMIT ?", maxID, rowLimit)
	if err != nil {
		log.Logger.Error().Msgf("cannot select %s [%s]", t.Name, err.Error())
		return 0, err
	}
	defer rows.Close()

	t.ResultSet = make([]mysqlUUID, 0)
	count := 0
	for rows.Next() {
		rowSet := mysqlUUID{}
		count++
		err = rows.Scan(&rowSet.ID, &rowSet.Discriminator)
		if err != nil {
			return 0, fmt.Errorf("select %s table error [%s]", t.Name, err.Error())
		}
		t.ResultSet = append(t.ResultSet, rowSet)
	}

	log.Logger.Info().Msgf("load %s [%d] records loaded", t.Name, count)
	return count, nil
}

func (t *uuidTable) save() error {
	tx, err := t.TargetDB.Begin()
	if err != nil {
		return err
	}
	stmt, err := tx.Prepare(pq.CopyIn(t.Name, "id", "discriminator"))
	if err != nil {
		return err
	}

	count := len(t.ResultSet)

	for _, uuid := range t.ResultSet {
		_, err := stmt.Exec(uuid.ID, uuid.Discriminator)
		if err != nil {
			return err
		}
	}

	t.ResultSet = []mysqlUUID{}

	_, err = stmt.Exec()
	if err != nil {
		return err
	}

	err = stmt.Close()
	if err != nil {
		return err
	}

	tx.Commit()
	log.Logger.Info().Msgf("save %s [%d] records saved", t.Name, count)

	return nil
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