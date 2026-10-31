#!/usr/bin/env bash
set -euo pipefail

chart=charts/paperless
app_values=(
  --set-string controllers.main.containers.main.env.PAPERLESS_REDIS=redis://redis.ci-services.svc.cluster.local:6379
  --set-string controllers.main.containers.main.env.PAPERLESS_SECRET_KEY=ci-only-secret-key-for-database-integration-tests
  --set persistence.data.type=emptyDir
  --set persistence.media.type=emptyDir
)

install_paperless() {
  local release=$1 namespace=$2
  shift 2
  helm upgrade --install "$release" "$chart" \
    --namespace "$namespace" --create-namespace \
    "${app_values[@]}" "$@" \
    --wait --timeout 10m
}

remove_release() {
  local release=$1 namespace=$2
  helm uninstall "$release" --namespace "$namespace" --wait --timeout 3m
  kubectl delete namespace "$namespace" --wait=true --timeout=3m
}

wait_for_command() {
  local namespace=$1 pod=$2
  shift 2
  for ((attempt = 0; attempt < 60; attempt++)); do
    if kubectl --namespace "$namespace" exec "$pod" -- "$@" >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
  done
  kubectl --namespace "$namespace" exec "$pod" -- "$@"
}

kubectl create namespace ci-services
kubectl --namespace ci-services run redis --image=redis:7.4-alpine --port=6379
kubectl --namespace ci-services expose pod redis --port=6379
wait_for_command ci-services redis redis-cli ping

install_paperless paperless paperless-sqlite
remove_release paperless paperless-sqlite

install_paperless paperless paperless-postgresql \
  --set postgresql.enabled=true \
  --set postgresql.auth.password=ci-only \
  --set postgresql.primary.persistence.enabled=false
remove_release paperless paperless-postgresql

kubectl create namespace paperless-external-postgresql
kubectl --namespace paperless-external-postgresql run postgres \
  --image=postgres:16-alpine --port=5432 \
  --env=POSTGRES_DB=paperless \
  --env=POSTGRES_USER=paperless \
  --env=POSTGRES_PASSWORD=ci-only
kubectl --namespace paperless-external-postgresql expose pod postgres --port=5432
kubectl --namespace paperless-external-postgresql create secret generic db-credentials \
  --from-literal=username=paperless --from-literal=password=ci-only
wait_for_command paperless-external-postgresql postgres \
  env PGPASSWORD=ci-only psql -h 127.0.0.1 -U paperless -d paperless -c 'SELECT 1'
install_paperless paperless paperless-external-postgresql \
  --set database.external.enabled=true \
  --set database.external.engine=postgresql \
  --set database.external.host=postgres \
  --set database.external.existingSecret.name=db-credentials
remove_release paperless paperless-external-postgresql

kubectl create namespace paperless-external-mariadb
kubectl --namespace paperless-external-mariadb run mariadb \
  --image=mariadb:11.4 --port=3306 \
  --env=MARIADB_ROOT_PASSWORD=ci-only-root \
  --env=MARIADB_DATABASE=paperless \
  --env=MARIADB_USER=paperless \
  --env=MARIADB_PASSWORD=ci-only
kubectl --namespace paperless-external-mariadb expose pod mariadb --port=3306
kubectl --namespace paperless-external-mariadb create secret generic db-credentials \
  --from-literal=username=paperless --from-literal=password=ci-only
wait_for_command paperless-external-mariadb mariadb \
  env MYSQL_PWD=ci-only mariadb -h 127.0.0.1 -u paperless paperless -e 'SELECT 1'
install_paperless paperless paperless-external-mariadb \
  --set database.external.enabled=true \
  --set database.external.engine=mariadb \
  --set database.external.host=mariadb \
  --set database.external.existingSecret.name=db-credentials
remove_release paperless paperless-external-mariadb

helm upgrade --install cnpg cloudnative-pg/cloudnative-pg \
  --version 0.29.1 \
  --namespace cnpg-system --create-namespace \
  --wait --timeout 5m
kubectl wait --for=condition=Established --timeout=2m crd/clusters.postgresql.cnpg.io
install_paperless paperless paperless-cloudnativepg \
  --set cloudnativepg.enabled=true
kubectl --namespace paperless-cloudnativepg wait \
  --for=condition=Ready --timeout=5m \
  cluster.postgresql.cnpg.io/paperless-cluster
