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

log_info "run aggregator revision [$GIT_REVISION]"

export PGPASSWORD=$KPI_DATABASE_PASSWORD

log_info connect to [$KPI_DATABASE_HOST:$KPI_DATABASE_PORT] with user [$KPI_DATABASE_USER] to database [$KPI_DATABASE_NAME]

connect="-h $KPI_DATABASE_HOST -U $KPI_DATABASE_USER -d $KPI_DATABASE_NAME -p $KPI_DATABASE_PORT"

log_info "wait for kpi database to be ready"
for retry in 1 2 3 4 5 6 7 8 9 10 ; do
    psql $connect -c "SELECT version();" >/dev/null
    if [[ $? == 0 ]] ; then
        if [[ "$retry" == "10" ]] ; then
            log_fatal "kpi database not ready stop retry"
            exit 1
        fi
        break
    fi
    log_warn "could not find kpi database - retry in 30 seconds"
    sleep 30
done

log_info "kpi database ready"

time=$(date +"%Y-%m-%dT%H:%M:%SZ")
psql $connect -f /tmp/aggregator.sql 2>&1 | sed 's/\"//g' | sed "s/.*/\{\"level\":\"info\",\"time\":\"$time\",\"message\":\"&\"\}/"

if [[ $? != 0 ]] ; then
    log_fatal "aggregator script run failed"
    exit 1
else
    log_info "aggregator script run was successful"
    exit 0
fi
