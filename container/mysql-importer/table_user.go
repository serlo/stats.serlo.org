package main

import (
	"database/sql"
	"time"

	"github.com/lib/pq"
	"github.com/go-sql-driver/mysql"
	"fmt"
)

type userTable struct {
	SourceDB *sql.DB
	TargetDB *sql.DB
	Name     string
	ResultSet     []mysqlUser
}

type mysqlUser struct {
	ID        int
	Email     string
	Username  string
	Logins    int
	Date      time.Time
	LastLogin mysql.NullTime
}

func (t *userTable) load(rowLimit int) (int, error) {
	maxID, err := getMaxID(t.TargetDB, t.Name)
	if err != nil {
		return 0, err
	}
	log.Logger.Info().Msgf("load [%s] max id [%d]", t.Name, maxID)

	rows, err := t.SourceDB.Query("SELECT id, date, email, last_login, logins, username FROM user WHERE id > ? ORDER BY id ASC LIMIT ?", maxID, rowLimit)
	if err != nil {
		log.Logger.Error().Msgf("cannot select %s [%s]", t.Name, err.Error())
		return 0, err
	}
	defer rows.Close()

	t.ResultSet = make([]mysqlUser, 0)
	count := 0
	for rows.Next() {
		rowSet := mysqlUser{}
		count++
		err = rows.Scan(&rowSet.ID, &rowSet.Date, &rowSet.Email, &rowSet.LastLogin, &rowSet.Logins, &rowSet.Username)
		if err != nil {
			return 0, fmt.Errorf("select %s table error [%s]", t.Name, err.Error())
		}
		t.ResultSet = append(t.ResultSet, rowSet)
	}

	log.Logger.Info().Msgf("load %s [%d] records imported\n", t.Name, count)
	return count, nil
}

func (t *userTable) save() error {
	tx, err := t.TargetDB.Begin()
	if err != nil {
		return err
	}

	stmt, err := tx.Prepare(pq.CopyIn(t.Name, "id", "date", "email", "last_login", "logins", "username"))
	if err != nil {
		return err
	}

	for _, data := range t.ResultSet {
		_, err := stmt.Exec(data.ID, data.Date, data.Email, data.LastLogin, data.Logins, data.Username)
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
	t.ResultSet= []mysqlUser{}
	return nil
}

func (t *userTable) create() error {
	stmts := []string{`CREATE TABLE public.user (
			id int8 NOT NULL CONSTRAINT user_primary_key PRIMARY KEY,
			email varchar(127) NOT NULL,
			username varchar(32) NOT NULL,
			logins int4 NOT NULL,
			date timestamp NOT NULL,
			last_login timestamp NULL,
			CONSTRAINT username_unique UNIQUE (username)
			);`,
		`CREATE INDEX user_logins ON public.user USING btree (logins);`,
		`CREATE INDEX user_date ON public.user USING btree (date);`,
		`CREATE INDEX user_last_login ON public.user USING btree (last_login);`,
	}
	return createTable(t.TargetDB, t.Name, stmts)
}
