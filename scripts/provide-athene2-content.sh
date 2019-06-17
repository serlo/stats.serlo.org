#!/bin/bash

set -e
pod_name="athene2-content-provider-app"
dump_file="tmp/dump.sql"

echo "wait for $pod_name to be ready"
until kubectl get pods --namespace="kpi" | grep $pod_name
do
  sleep 5
done

if [[ ! -f $dump_file ]] ; then
    echo "cold not find database dump!"
    exit 1
fi

pod=$(kubectl get pods --namespace="kpi" | grep $pod_name | awk '{ print $1 }')
kubectl_args="-c athene2-content-provider --namespace=kpi"

if kubectl exec -it $pod $kubectl_args -- ls -l /tmp/dump.sql ; then
    echo "sql dump already present in athene2-content-provider"
else
    echo "copy sql dump to athene2-content-provider"
    kubectl cp $dump_file $pod:/tmp/dump.sql $kubectl_args 
fi
