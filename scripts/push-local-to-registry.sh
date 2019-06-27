#
# push local images to minikube registry
#
set -e

registry=$(minikube ip):5000
image_local=serlo/athene2-dbsetup-cronjob:latest
image_remote=serlo-containers/athene2-dbsetup-cronjob:latest
docker tag  $image_local $registry/$image_remote
docker push $registry/$image_remote

image_local=serlo/kpi-aggregator:latest
image_remote=serlo-containers/kpi-aggregator:latest
docker tag  $image_local $registry/$image_remote
docker push $registry/$image_remote

image_local=serlo/kpi-mysql-importer:latest
image_remote=serlo-containers/kpi-mysql-importer:latest
docker tag  $image_local $registry/$image_remote
docker push $registry/$image_remote
