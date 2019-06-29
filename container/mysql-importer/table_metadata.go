package main

import (
	"database/sql"
	"github.com/lib/pq"
	"fmt"
)

type metadataTable struct {
	SourceDB *sql.DB
	TargetDB *sql.DB
	Name     string
	ResultSet []mysqlMetadata
}

type mysqlMetadata struct {
	ID     int
	UUIDID int
	Value  string
	KeyID  int
}

func (t *metadataTable) load(rowLimit int) (int, error) {
	maxID, err := getMaxID(t.TargetDB, t.Name)
	if err != nil {
		return 0, err
	}
	log.Logger.Info().Msgf("load [%s] max id [%d]", t.Name, maxID)

	rows, err := t.SourceDB.Query("SELECT id, uuid_id, value, key_id FROM metadata WHERE id > ? ORDER BY id DESC LIMIT ?", maxID, rowLimit)
	if err != nil {
		log.Logger.Error().Msgf("cannot select %s [%s]", t.Name, err.Error())
		return 0, err
	}
	defer rows.Close()

	t.ResultSet = make([]mysqlMetadata, 0)
	count := 0
	for rows.Next() {
		data := mysqlMetadata{}
		count++
		err = rows.Scan(&data.ID, &data.UUIDID, &data.Value, &data.KeyID)
		if err != nil {
			return 0, fmt.Errorf("select %s table error [%s]", t.Name, err.Error())
		}
		t.ResultSet = append(t.ResultSet, data)
	}

	log.Logger.Info().Msgf("load %s [%d] records imported\n", t.Name, count)
	return count, nil
}

func (t *metadataTable) save() error {
	tx, err := t.TargetDB.Begin()
	if err != nil {
		return err
	}

	stmt, err := tx.Prepare(pq.CopyIn(t.Name, "id", "uuid_id", "value", "key_id"))
	if err != nil {
		return err
	}
	for _, data := range t.ResultSet {
		_, err := stmt.Exec(data.ID, data.UUIDID, data.Value, data.KeyID)
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
	t.ResultSet= []mysqlMetadata{}

	return nil
}

func (t *metadataTable) create() error {
	stmts := []string{`CREATE TABLE public.metadata (
				id int8 NOT NULL CONSTRAINT metadata_primary_key PRIMARY KEY,
				uuid_id int8 NOT NULL REFERENCES uuid(id),
				key_id int8 NOT NULL,
				value varchar(255) NOT NULL
				);`,
		`CREATE INDEX metadata_uuid_id ON public.metadata USING btree (uuid_id);`,
	}
	return createTable(t.TargetDB, t.Name, stmts)
}
