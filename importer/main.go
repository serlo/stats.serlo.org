package main

import (
	"database/sql"
	"fmt"
	"os"
	"time"

	"github.com/go-sql-driver/mysql"
	_ "github.com/go-sql-driver/mysql"
	_ "github.com/lib/pq"
)

type mysqlUser struct {
	ID        string
	Email     string
	Username  string
	Logins    int
	Date      time.Time
	LastLogin mysql.NullTime
}

func main() {
	sourceDB := openSourceDB()
	defer sourceDB.Close()
	targetDB := openTargetDB()
	defer targetDB.Close()

	err := createTableUser(targetDB)
	if err == nil {
		err = importUser(sourceDB, targetDB)
	}
	if err != nil {
		fmt.Printf("import failed [%s]\n", err.Error())
		os.Exit(1)
	}
}

func createTableUser(targetDB *sql.DB) error {
	stmt := `SELECT EXISTS (
		SELECT 1
		FROM   information_schema.tables 
		WHERE  table_schema = 'public'
		AND    table_name = 'user'
		)
	`
	rows, err := targetDB.Query(stmt)
	if err != nil {
		return err
	}
	defer rows.Close()
	for rows.Next() {
		result := false
		rows.Scan(&result)
		if !result {
			fmt.Printf("'create table user\n")
			stmts := []string{`CREATE TABLE public.user (
				id int8 NOT NULL CONSTRAINT primary_key PRIMARY KEY,
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
			for _, stmt := range stmts {
				_, err := targetDB.Exec(stmt)
				if err != nil {
					return fmt.Errorf("create table user failed [%s]", err.Error())
				}
			}
			return nil
		}
		return nil
	}

	return nil
}

func importUser(sourceDB *sql.DB, targetDB *sql.DB) error {
	rows, err := sourceDB.Query("select id, date, email, last_login, logins, username from user")
	if err != nil {
		fmt.Printf("cannot select users [%s]", err.Error())
		os.Exit(1)
	}
	defer rows.Close()

	for rows.Next() {
		user := mysqlUser{}
		err = rows.Scan(&user.ID, &user.Date, &user.Email, &user.LastLogin, &user.Logins, &user.Username)
		if err != nil {
			return fmt.Errorf("select user table error [%s]", err.Error())
		}
		stmt := fmt.Sprintf("INSERT INTO public.user (id, email, logins, username, date, last_login) VALUES ($1, $2, $3, $4, $5, $6);")
		_, err = targetDB.Exec(stmt, user.ID, user.Email, user.Logins, user.Username, user.Date, user.LastLogin)
		if err != nil {
			return fmt.Errorf("insert user table error [%s]", err.Error())
		}
	}
	return nil
}

func openSourceDB() *sql.DB {
	db, err := sql.Open("mysql", "root:admin@tcp(mysql.serlo.local:30000)/serlo?parseTime=true")

	// if there is an error opening the connection, handle it
	if err != nil {
		fmt.Printf("cannot open source database [%s]\n", err.Error())
		os.Exit(1)
	}
	return db
}

func openTargetDB() *sql.DB {
	psqlInfo := fmt.Sprintf("host=postgres.serlo.local port=30002 user=postgres password=admin dbname=postgres sslmode=disable")
	db, err := sql.Open("postgres", psqlInfo)

	// if there is an error opening the connection, handle it
	if err != nil {
		fmt.Printf("cannot open target database [%s]\n", err.Error())
		os.Exit(1)
	}
	return db
}
