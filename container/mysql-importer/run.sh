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

if [[ -d /var/run/importer.lock ]] ; then
    log_ino "skip athene2 importer run as importer is still active"
else
    log_info "run athene2 importer revision [$GIT_REVISION]"
    echo "" >/var/run/importer.lock
    cd /tmp && ./goapp
fi
rm /var/run/importer.lock

