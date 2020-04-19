package main

import (
	"database/sql"
	"github.com/lib/pq"
	"fmt"
)

type entityLinkTable struct {
	SourceDB *sql.DB
	TargetDB *sql.DB
	Name     string
	ResultSet []mysqlEntityLink
}

type mysqlEntityLink struct {
	ID           int
	ParentID     int
	ChildID      int
	TypeID       int
}

func (t *entityLinkTable) name() string {
	return t.Name
}

func (t *entityLinkTable) load(maxID int, rowLimit int) (int, error) {
	log.Logger.Info().Msgf("load [%s] id > [%d]", t.Name, maxID)
	rows, err := t.SourceDB.Query("SELECT id, parent_id, child_id, type_id FROM entity_link WHERE id > ? ORDER BY id ASC LIMIT ?", maxID, rowLimit)
	if err != nil {
		log.Logger.Error().Msgf("cannot select %s [%s]", t.Name, err.Error())
		return 0, err
	}
	defer rows.Close()


	t.ResultSet = make([]mysqlEntityLink, 0)
	count := 0
	for rows.Next() {
		data := mysqlEntityLink{}
		count++
		err = rows.Scan(&data.ID, &data.ParentID, &data.ChildID, &data.TypeID)
		if err != nil {
			return 0, fmt.Errorf("select %s table error [%s]", t.Name, err.Error())
		}
		t.ResultSet = append(t.ResultSet, data)
	}

	log.Logger.Info().Msgf("load %s [%d] records loaded", t.Name, count)
	return count, nil
}

func (t *entityLinkTable) save() error {
	tx, err := t.TargetDB.Begin()
	if err != nil {
		return err
	}

	stmt, err := tx.Prepare(pq.CopyIn(t.Name, "id", "parent_id", "child_id", "type_id"))
	if err != nil {
		return err
	}

	count := len(t.ResultSet)

	for _, data := range t.ResultSet {
		_, err := stmt.Exec(data.ID, data.ParentID, data.ChildID, data.TypeID)
		if err != nil {
			return err
		}
	}
	t.ResultSet= []mysqlEntityLink{}

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


func (t *entityLinkTable) create() error {
	stmts := []string{`CREATE TABLE public.entity_link (
		id int8 NOT NULL CONSTRAINT entity_link_primary_key PRIMARY KEY,
		parent_id int8 NOT NULL,
		child_id int8 NOT NULL,
		type_id int8 NOT NULL
		);`,
		`CREATE INDEX entity_link_parent_id ON public.entity_link USING btree (parent_id);`,
	}
	return createTable(t.TargetDB, t.Name, stmts)
}
