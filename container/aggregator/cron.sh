#!/bin/sh

log_info() {
    time=$(date +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"level\":\"info\",\"time\":\"$time\",\"message\":\"$1\"}"
}

log_warn() {
    time=$(date +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"level\":\"warn\",\"time\":\"$time\",\"message\":\"$1\"}"
}

exit_script() {
  trap - SIGINT SIGTERM # clear the trap
  log_warn "cron script shutdown"
}


log_info "run initial kpi aggregation"
out=$(/tmp/run)
if [[ $? != 0 ]] ; then
    log_warn "kpi aggregation failed error [$?] output [$out]"
fi

log_info "start with cron pattern [${CRON_PATTERN}]"

/bin/sh -c "echo \"${CRON_PATTERN} /tmp/run\" | crontab - && crond -f -L /dev/stdout"
