#!/bin/sh

set -e

log_info() {
    time=$(date +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"level\":\"info\",\"time\":\"$time\",\"message\":\"$1\"}"
}

log_warn() {
    time=$(date +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"level\":\"warn\",\"time\":\"$time\",\"message\":\"$1\"}"
}

log_info "run initial athene2 database importer"
cd /tmp && ./run

log_info "start with cron pattern [${CRON_PATTERN}]"
echo "${CRON_PATTERN} /tmp/run" | crontab -
crond -f -L /dev/stdout &

log_info "crond running, quit with CTRL+C"
trap "kill $!" SIGINT SIGTERM
wait