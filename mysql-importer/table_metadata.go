package main

import (
	"database/sql"
)

type metadataTable struct {
	SourceDB *sql.DB
	TargetDB *sql.DB
	Name     string
}

// any reason we cannot join event_log and event?
type mysqlMetadata struct {
	ID     int
	UUIDID int
	Value  string
	KeyID  int
}

func (t *metadataTable) insertData(metadata *mysqlMetadata) func() []interface{} {
	return func() []interface{} {
		return []interface{}{
			(*metadata).ID, (*metadata).UUIDID, (*metadata).Value, (*metadata).KeyID}
	}
}

func (t *metadataTable) load() error {
	data := mysqlMetadata{}
	return loadTable(t.SourceDB,
		t.TargetDB,
		t.Name,
		"SELECT id, uuid_id, value, key_id FROM metadata WHERE id > ?",
		[]interface{}{&data.ID, &data.UUIDID, &data.Value, &data.KeyID},
		"INSERT INTO public.metadata (id, uuid_id, value, key_id) VALUES ($1, $2, $3, $4);",
		t.insertData(&data))
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
