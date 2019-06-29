#!/bin/sh

cmd="varnishd -s malloc,${VARNISH_MEMORY} -a :80 -f ${VARNISH_CONFIG_FILE}"

echo "Start varnishd with  $cmd"
mkdir -p /var/lib/varnish/`hostname` && chown nobody /var/lib/varnish/`hostname`
$cmd

sleep 1

echo "Start collecting metrics and monitor varnishd"
while true ; do
    ps -aux | grep varnishd >/dev/null
    if [[ $? != 0 ]]; then 
        echo varnishd process died
        sleep 5
        exit 1
    fi
	stats=$(varnishstat -j -f MAIN.cache_hit -f MAIN.cache_miss | jq 'del(."MAIN.cache_hit".description)' | grep -v "format" | grep -v "description" | sed 's/MAIN.//' | tr '\n' ' ' | tr -d [:blank:])
	echo $stats
	sleep 15
done


