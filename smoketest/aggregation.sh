#!/bin/sh
set -e
importer_pod=$(kubectl get pods --namespace kpi | grep "mysql-importer" | awk '{print $1}')
aggregator_pod=$(kubectl get pods --namespace kpi | grep "aggregator" | awk '{print $1}')
psql_pod=$(kubectl get pods --namespace kpi | grep "postgres" | awk '{print $1}')
echo "using pods: $importer_pod, $psql_pod, $aggregator_pod"

importer_exec () {
    kubectl exec -it $importer_pod --namespace kpi -- /bin/sh -c "$1"
}

aggregator_exec () {
    kubectl exec -it $aggregator_pod --namespace kpi -- /bin/sh -c "$1"
}

psql_exec () {
    kubectl exec -it $psql_pod --namespace kpi -- su - postgres -c "$1"
}

tables=""
get_tables() {
	psql_exec 'psql -d kpi --no-align -P tuples_only -c "SELECT tablename FROM pg_catalog.pg_tables WHERE tablename LIKE '\''cache_%'\'';"' | awk 1 RS="\r\n" ORS=' '
}

dump_tables() {
    for table in $tables;
    do
        psql_exec "pg_dump --column-inserts -d kpi -a -t $table" | sort > /tmp/kpi_dump_$1_$table
    done
}

compare_tables() {
    for table in $tables;
    do
        diff /tmp/kpi_dump_incremental_$table /tmp/kpi_dump_idempotence_$table
        diff /tmp/kpi_dump_incremental_$table /tmp/kpi_dump_complete_$table
    done
}

DOCKER_ENV=$(minikube docker-env)
eval $DOCKER_ENV
echo "restarting psql..."
docker restart $(docker ps | grep k8s_postgres | cut -d " " -f 1)
sleep 5

echo "========= testing incremental import =========="
echo "deleting kpi database..."
psql_exec "dropdb --if-exists kpi"

finished="false"
while [ "$finished" != "true" ]
do
	finished=$(
		importer_exec "KPI_MYSQL_IMPORT_ONLY_FIRST_CHUNK=true /tmp/run" \
		| tee /dev/stderr \
		| grep "sourceMaxID" \
		| jq '.sourceMaxID != null and .targetMaxID != null and .sourceMaxID == .targetMaxID' \
		| grep "false" || echo "true" \
	)
	aggregator_exec "/tmp/run"
done

tables=$( get_tables )
echo "dumping tables..."
dump_tables incremental


echo "========= testing aggregator idempotence =========="
echo "testing aggregator idempotence..."
for i in 1 2 3;
do	
	aggregator_exec "/tmp/run"
done

echo "dumping tables..."
dump_tables idempotence

echo "========= testing complete import =========="
echo "deleting kpi database..."
psql_exec "dropdb --if-exists kpi"
importer_exec "KPI_MYSQL_IMPORT_ONLY_FIRST_CHUNK=false /tmp/run"
aggregator_exec "/tmp/run"

echo "dumping tables..."
dump_tables complete

echo "========= checking diffs ============="
compare_tables

