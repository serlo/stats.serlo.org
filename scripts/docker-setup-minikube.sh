#!/bin/sh

set -e

image="$1"
tag="$2"

if [ "$image" = "" ] ; then
    echo "script requires image name"
    exit 1
fi

eval $(minikube docker-env)
greptag=$(echo $tag | sed s/latest//g)
available=$(docker images | (grep -F "$image" || echo "") | (grep -F "$greptag" || echo ""))
if [ ! -z "$available" ] ; then
   echo "nothing to do image $image:$tag available"
   exit 0 
fi

docker pull $image:$tag
eval $(minikube docker-env -u)
rm -f tmp.image
