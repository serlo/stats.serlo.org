#!/bin/bash

set -e
pod_name="dbsetup-cronjob"
dump_file="tmp/dump.sql"

echo "wait for $pod_name to be ready"
until kubectl get pods --all-namespaces | grep $pod_name
do
  sleep 5
done

if [[ ! -f $dump_file ]] ; then
    echo "cold not find database dump!"
    exit 1
fi
namespace="$(kubectl get pods --all-namespaces | grep $pod_name | head -1 | awk '{ print $1 }')"
pod="$(kubectl get pods --all-namespaces | grep $pod_name | head -1 | awk '{ print $2 }')"
kubectl_args="--namespace $namespace -c dbsetup-container"

if kubectl exec -it $pod $kubectl_args -- ls -l /tmp/dump.sql >/dev/null 2>/dev/null; then
    echo "sql dump already present in dbsetup-cronjob"
else
    echo "copy sql dump [$dump_file] to pod [$pod] args [$kubectl_args]"
    kubectl cp $dump_file $pod:/tmp/dump.sql $kubectl_args 
fi
