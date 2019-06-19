#!/bin/sh

if [[ -d /var/run/importer.lock ]] ; then
    echo "skip athene2 importer run as importer is still active"
else
    echo "run athene2 importer revision [$GIT_REVISION]"
    echo "" >/var/run/importer.lock
    cd /app
    ./goapp
fi
rm /var/run/importer.lock

