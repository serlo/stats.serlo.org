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

log_info "run anonymizer revision [$GIT_REVISION]"

if [[ "$ATHENE2_DATABASE_HOST" == "" ]] ; then
    log_fatal "database host not set"
fi

connect="-h $ATHENE2_DATABASE_HOST --port $ATHENE2_DATABASE_PORT -u $ATHENE2_DATABASE_USER -p$ATHENE2_DATABASE_PASSWORD"

until mysql $connect -e "SHOW DATABASES" >/dev/null 2>/dev/null
do 
    log_warn "could not connect to athene2 database instance error [$?]- retrying later"
    sleep 10
done

log_info "dump of serlo database - start"

log_info "dump schema"
mysqldump $connect \
    --no-data \
    --lock-tables=false \
    --add-drop-database \
    serlo \
    > /tmp/dump.sql

if [[ $? != 0 ]] ; then
    log_error "could not dump schema error [$?]- retrying later"
    exit 1
fi

log_info "dump data"
mysqldump $connect \
    --no-create-info \
    --lock-tables=false \
    --add-locks \
    serlo \
    >> /tmp/dump.sql

if [[ $? != 0 ]] ; then
    log_error "could not dump data error [$?]- retrying later"
    exit 1
fi

log_info "anonymize content"
sed -i -r "/([0-9]+, ?)'[^']+\@[^']+', ?'[^']+', ?'[^']+',( ?[0-9]+, ?'[^']+', ?[0-9], ?)'[^']+'/ s//\1CONCAT\(LEFT\(UUID\(\), 8\),'@localhost'\), LEFT\(UUID\(\), 8\), '8a534960a8a4c8e348150a0ae3c7f4b857bfead4f02c8cbf0d',\2LEFT\(UUID\(\), 8\)/" /tmp/dump.sql

if [[ $? != 0 ]] ; then
    log_error "could not dump data error [$?]- retrying later"
    exit 1
fi

log_info "compress dump"
cd /tmp && tar -czvf dump.tar.gz dump.sql >/dev/null
if [[ $? != 0 ]] ; then
    log_error "could not compress dump error [$?]- retrying later"
    exit 1
fi

log_info "dump of serlo database - end"
