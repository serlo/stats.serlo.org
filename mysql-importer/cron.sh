#!/bin/sh

echo "initial importer run"
cd /app
./run

echo "start cronjob with cron pattern [${CRON_PATTERN}]"

/bin/sh -c "echo \"${CRON_PATTERN} /app/run\" | crontab - && crond -f -L /dev/stdout"
