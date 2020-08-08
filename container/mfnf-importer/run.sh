#!/bin/sh

log_info() {
    time=$(date +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"level\":\"info\",\"time\":\"$time\",\"message\":\"$1\"}"
}

log_fatal() {
    time=$(date +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"level\":\"fatal\",\"time\":\"$time\",\"message\":\"$1\"}"
}

log_warn() {
    time=$(date +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"level\":\"warn\",\"time\":\"$time\",\"message\":\"$1\"}"
}

log_info "run mfnf-importer [$GIT_REVISION]"

export PGPASSWORD=$KPI_DATABASE_PASSWORD

log_info "connect to [$KPI_DATABASE_HOST:$KPI_DATABASE_PORT] with user [$KPI_DATABASE_USER] to database [$KPI_DATABASE_NAME]"

connect="-h $KPI_DATABASE_HOST -U $KPI_DATABASE_USER -d $KPI_DATABASE_NAME -p $KPI_DATABASE_PORT"

log_info "wait for kpi database to be ready"
for retry in 1 2 3 4 5 6 7 8 9 10 ; do
    psql $connect -c "SELECT version();" >/dev/null 2>&1
    if [[ $? == 0 ]] ; then
        if [[ "$retry" == "10" ]] ; then
            log_fatal "kpi database not ready stop retry"
            exit 1
        fi
        break
    fi
    log_warn "could not find kpi database - retry in 60 seconds"
    sleep 60
done

log_info "kpi database ready"

time=$(date +"%Y-%m-%dT%H:%M:%SZ")
psql -v ON_ERROR_STOP=1 $connect <<EOF
CREATE TABLE IF NOT EXISTS mfnf_edits (
	id INT(11) NOT NULL AUTO_INCREMENT,
	date DATE,
	name CHAR(255),
	topic CHAR(255),
	number_of_edits INT(11),
	PRIMARY KEY ( id ),
	UNIQUE (date, name, topic)
);
EOF

if [[ $? != 0 ]] ; then
    log_fatal "failed to create mfnf_edits table"
    exit 1
else
    log_info "table mfnf_edits created (or it did already exist)"
    exit 0
fi

python3 src/authors_MfNF.py | psql $connect
