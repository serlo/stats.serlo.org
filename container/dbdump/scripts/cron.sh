#!/bin/sh

log_info() {
    time=$(date +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"level\":\"info\",\"time\":\"$time\",\"message\":\"$1\"}"
}

if [[ "${ENVIRONMENT}" == "docker" ]] ; then
    log_info "started in local docker environment call run script directly"
    /tmp/run
    exit 0
else
    log_info "start with cron pattern [${CRON_PATTERN}]"
    echo "${CRON_PATTERN} /tmp/run" | crontab -
    crond -f -L /dev/stdout &

    log_info "crond running, quit with CTRL+C"
    trap "kill $!" SIGINT SIGTERM
    wait
fi

