#!/bin/sh

set -e

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

exit_script() {
  trap - SIGINT SIGTERM # clear the trap
  log_warn "run script shutdown"
}

trap exit_script SIGINT SIGTERM

log_info "run athene2 dbsetup revision $GIT_REVISION"

connect="-h $ATHENE2_DATABASE_HOST --port $ATHENE2_DATABASE_PORT -u $ATHENE2_DATABASE_USER -p$ATHENE2_DATABASE_PASSWORD"

log_info "wait for athene2 database to be ready"
until mysql $connect -e "SHOW DATABASES" >/dev/null 2>/dev/null
do 
    log_warn "could not find athene2 server up and running trying later"
    sleep 10
done

log_info "check if athene2 database is empty"
mysql $connect -e "SHOW DATABASES" | grep "serlo" >/dev/null 2>/dev/null
if [[ $? != 0 ]] ; then
    log_info "could not find athene2 dabase lets import the latest dump"
    if [[ -f /tmp/dump.sql ]] ; then
        mysql $connect </tmp/dump.sql
        if [[ $? != 0 ]] ; then
            log_warn "could not import athene2 database dump - trying later"
        else
            log_info "import athene2 database dump was successful"
        fi
    else
        log_info "athene2 database is empty but no dump file present trying later"
    fi
else
    log_info "athene2 database next check for empty database in 5 min"
    sleep 300
fi


