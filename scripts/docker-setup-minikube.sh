#!/bin/sh

image="$1"
tag="$2"

if [ "$image" = "" ] ; then
    echo script requires image name
    exit 1
fi

eval $(minikube docker-env)
if [ "$tag" = "latest" ] ; then
    docker images | grep -F $image
else
    docker images | grep -F $image | grep -F $tag
fi

if [ $? = 0 ] ; then
   echo "nothing to do image $image:$tag available"
   exit 0 
fi

eval $(minikube docker-env -u)
docker pull $image:$tag
docker save $image:$tag >tmp.image
eval $(minikube docker-env)
docker load <tmp.image
eval $(minikube docker-env -u)
rm -f tmp.image