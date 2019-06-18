#!/bin/sh

echo "initial importer run"
./goapp

echo "start cronjob with cron pattern [${CRON_PATTERN}]"

/bin/sh -c "echo \"${CRON_PATTERN} /tmp/run\" | crontab - && crond -f -L /dev/stdout"
