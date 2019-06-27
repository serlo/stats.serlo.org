#
# push gcr images to minikube registry
#

set -e

gcr_registry=eu.gcr.io:443
registry=$(minikube ip):5000
image=serlo-containers/athene2-dbsetup-cronjob:latest
docker tag $gcr_registry/$image $registry/$image
docker push $registry/$image
image=serlo-containers/kpi-aggregator:latest
docker tag  $gcr_registry/$image $registry/$image
docker push $registry/$image
image=serlo-containers/kpi-mysql-importer:latest
docker tag  $gcr_registry/$image $registry/$image
docker push $registry/$image
