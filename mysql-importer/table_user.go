package main

import (
	"database/sql"
	"time"

	"github.com/go-sql-driver/mysql"
)

type userTable struct {
	SourceDB *sql.DB
	TargetDB *sql.DB
	Name     string
}

type mysqlUser struct {
	ID        int
	Email     string
	Username  string
	Logins    int
	Date      time.Time
	LastLogin mysql.NullTime
}

func (t *userTable) insertData(data *mysqlUser) func() []interface{} {
	return func() []interface{} {
		return []interface{}{
			(*data).ID, (*data).Date, (*data).Email, (*data).LastLogin, (*data).Logins, (*data).Username}
	}
}

func (t *userTable) load() error {
	data := mysqlUser{}
	return loadTable(t.SourceDB,
		t.TargetDB,
		t.Name,
		"SELECT id, date, email, last_login, logins, username FROM user WHERE id > ?",
		[]interface{}{&data.ID, &data.Date, &data.Email, &data.LastLogin, &data.Logins, &data.Username},
		"INSERT INTO public.user (id, date, email, last_login, logins, username) VALUES ($1, $2, $3, $4, $5, $6);",
		t.insertData(&data))
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
