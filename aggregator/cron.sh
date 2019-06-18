#!/bin/sh

echo "start with cron pattern [${CRON_PATTERN}]"

/bin/sh -c "echo \"${CRON_PATTERN} /tmp/run\" | crontab - && crond -f -L /dev/stdout"
