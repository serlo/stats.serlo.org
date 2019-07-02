#!/bin/sh

log_info() {
    time=$(date +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"level\":\"info\",\"time\":\"$time\",\"message\":\"$1\"}"
}

log_warn() {
    time=$(date +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"level\":\"warn\",\"time\":\"$time\",\"message\":\"$1\"}"
}

log_info "run initial kpi aggregation"
/tmp/run
if [[ $? != 0 ]] ; then
    log_warn "kpi aggregation failed error [$?]"
fi

log_info "start with cron pattern [${CRON_PATTERN}]"
echo "${CRON_PATTERN} /tmp/run" | crontab -
crond -f -L /dev/stdout >/dev/null & 

log_info "crond running, quit with CTRL+C"
trap "kill $!" SIGINT SIGTERM
wait
