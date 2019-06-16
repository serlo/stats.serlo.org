#!/bin/bash

exit_script() {
    time=$(date +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"level\":\"info\",\"time\":\"$time\",\"message\":\"shutingdown\"}"
    trap - SIGINT SIGTERM # clear the trap
    kill -- -$$ # Sends SIGTERM to child/sub processes
}

trap exit_script SIGINT SIGTERM

connect="-h $ATHENE2_DATABASE_HOST --port $ATHENE2_DATABASE_PORT -u $ATHENE2_DATABASE_USER -p$ATHENE2_DATABASE_PASSWORD"

while true; do
    time=$(date +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"level\":\"info\",\"time\":\"$time\",\"message\":\"wait for athene2 database to be ready\"}"
    until mysql $connect -e "SHOW DATABASES" >/dev/null 2>/dev/null
    do 
        time=$(date +"%Y-%m-%dT%H:%M:%SZ")
        echo "{\"level\":\"info\",\"time\":\"$time\",\"message\":\"could not find athene2 server up and running trying later\"}"
        sleep 10
    done

    time=$(date +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"level\":\"info\",\"time\":\"$time\",\"message\":\"check if athene2 database is empty\"}"
    mysql $connect -e "SHOW DATABASES" | grep "serlo" >/dev/null 2>/dev/null
    if [[ $? != 0 ]] ; then
        time=$(date +"%Y-%m-%dT%H:%M:%SZ")
        echo "{\"level\":\"info\",\"time\":\"$time\",\"message\":\"could not find athene2 dabase lets import the latest dump\"}"
        if [[ -f /tmp/dump.sql ]] ; then
            mysql $connect </tmp/dump.sql
            if [[ $? != 0 ]] ; then
                time=$(date +"%Y-%m-%dT%H:%M:%SZ")
                echo "{\"level\":\"info\",\"time\":\"$time\",\"message\":\"could not import athene2 database dump trying later\"}"
            else
                time=$(date +"%Y-%m-%dT%H:%M:%SZ")
                echo "{\"level\":\"info\",\"time\":\"$time\",\"message\":\"import athene2 database dump was successful\"}"
            fi
        else
            time=$(date +"%Y-%m-%dT%H:%M:%SZ")
            echo "{\"level\":\"info\",\"time\":\"$time\",\"message\":\"athene2 database is empty but no dump file present trying later\"}"
        fi
    else
        time=$(date +"%Y-%m-%dT%H:%M:%SZ")
        echo "{\"level\":\"info\",\"time\":\"$time\",\"message\":\"athene2 database check for empty in 300s\"}"
        sleep 300
    fi

    sleep 60
done;
