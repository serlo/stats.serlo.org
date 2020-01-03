#!/bin/sh

set -e

image="$1"
tag="$2"

if [ "$image" = "" ] ; then
    echo "script requires image name"
    exit 1
fi

eval $(minikube docker-env)
docker pull $image:$tag
eval $(minikube docker-env -u)
