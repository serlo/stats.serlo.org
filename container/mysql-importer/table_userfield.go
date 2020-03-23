package main

import (
	"database/sql"

	"github.com/lib/pq"
	"fmt"
)

type userFieldTable struct {
	SourceDB *sql.DB
	TargetDB *sql.DB
	Name     string
	ResultSet     []mysqlUserField
}

type mysqlUserField struct {
	ID        int
	UserID    int
	Field     string
	Value     string
}

func (t *userFieldTable) name() string {
	return t.Name
}

func (t *userFieldTable) load(maxID int, rowLimit int) (int, error) {
	log.Logger.Info().Msgf("load [%s] id > [%d]", t.Name, maxID)

	rows, err := t.SourceDB.Query("SELECT id, user_id, field, value FROM user_field WHERE id > ? ORDER BY id ASC LIMIT ?", maxID, rowLimit)
	if err != nil {
		log.Logger.Error().Msgf("cannot select %s [%s]", t.Name, err.Error())
		return 0, err
	}
	defer rows.Close()

	t.ResultSet = make([]mysqlUserField, 0)
	count := 0
	for rows.Next() {
		rowSet := mysqlUserField{}
		count++
		err = rows.Scan(&rowSet.ID, &rowSet.UserID, &rowSet.Field, &rowSet.Value)
		if err != nil {
			return 0, fmt.Errorf("select %s table error [%s]", t.Name, err.Error())
		}
		t.ResultSet = append(t.ResultSet, rowSet)
	}

	log.Logger.Info().Msgf("load %s [%d] records loaded", t.Name, count)
	return count, nil
}

func (t *userFieldTable) save() error {
	tx, err := t.TargetDB.Begin()
	if err != nil {
		return err
	}

	stmt, err := tx.Prepare(pq.CopyIn(t.Name, "id", "user_id", "field", "value"))
	if err != nil {
		return err
	}

	count := len(t.ResultSet)

	for _, data := range t.ResultSet {
		_, err := stmt.Exec(data.ID, data.UserID, data.Field, data.Value)
		if err != nil {
			return err
		}
	}
	t.ResultSet= []mysqlUserField{}

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

func (t *userFieldTable) create() error {
	stmts := []string{`CREATE TABLE public.user_field (
			id int PRIMARY KEY,
			user_id bigint NOT NULL,
                        field text NOT NULL,
                        value text NOT NULL
			);`,
		`CREATE INDEX user_id_idx ON public.user_field USING btree (user_id);`,
	}
	return createTable(t.TargetDB, t.Name, stmts)
}
