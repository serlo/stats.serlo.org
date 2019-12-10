package main

import (
	"database/sql"
	"github.com/lib/pq"
	"time"
	"fmt"
)

type entityRevisionTable struct {
	SourceDB *sql.DB
	TargetDB *sql.DB
	Name     string
	ResultSet []mysqlEntityRevision
}

type mysqlEntityRevision struct {
	ID           int
	AuthorID     int
	RepositoryID int
	Date         time.Time
}

func (t *entityRevisionTable) name() string {
	return t.Name
}

func (t *entityRevisionTable) load(maxID int, rowLimit int) (int, error) {
	log.Logger.Info().Msgf("load [%s] id > [%d]", t.Name, maxID)
	rows, err := t.SourceDB.Query("SELECT id, author_id, repository_id, date FROM entity_revision WHERE id > ? ORDER BY id ASC LIMIT ?", maxID, rowLimit)
	if err != nil {
		log.Logger.Error().Msgf("cannot select %s [%s]", t.Name, err.Error())
		return 0, err
	}
	defer rows.Close()


	t.ResultSet = make([]mysqlEntityRevision, 0)
	count := 0
	for rows.Next() {
		data := mysqlEntityRevision{}
		count++
		err = rows.Scan(&data.ID, &data.AuthorID, &data.RepositoryID, &data.Date)
		if err != nil {
			return 0, fmt.Errorf("select %s table error [%s]", t.Name, err.Error())
		}
		t.ResultSet = append(t.ResultSet, data)
	}

	log.Logger.Info().Msgf("load %s [%d] records loaded", t.Name, count)
	return count, nil
}

func (t *entityRevisionTable) save() error {
	tx, err := t.TargetDB.Begin()
	if err != nil {
		return err
	}

	stmt, err := tx.Prepare(pq.CopyIn(t.Name, "id", "author_id", "repository_id", "date"))
	if err != nil {
		return err
	}

	count := len(t.ResultSet)

	for _, data := range t.ResultSet {
		_, err := stmt.Exec(data.ID, data.AuthorID, data.RepositoryID, data.Date)
		if err != nil {
			return err
		}
	}
	t.ResultSet= []mysqlEntityRevision{}

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


func (t *entityRevisionTable) create() error {
	stmts := []string{`CREATE TABLE public.entity_revision (
		id int8 NOT NULL CONSTRAINT entity_revision_primary_key PRIMARY KEY,
		author_id int8 NOT NULL REFERENCES "user"(id),
		repository_id int8 NOT NULL REFERENCES uuid(id),
		date timestamp NOT NULL,
		);`,
		`CREATE INDEX entity_revision_author_id ON public.entity_revision USING btree (author_id);`,
	}
	return createTable(t.TargetDB, t.Name, stmts)
}
