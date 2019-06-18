#!/bin/sh

echo "run initial aggregation at the beginning"
/tmp/run

echo "start with cron pattern [${CRON_PATTERN}]"

/bin/sh -c "echo \"${CRON_PATTERN} /tmp/run\" | crontab - && crond -f -L /dev/stdout"
