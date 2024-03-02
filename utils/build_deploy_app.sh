#!/usr/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

cd $SCRIPT_DIR/../app &&
docker build -t devops-exam:1.0.0 . &&
cd ../infra/charts/app &&

helm upgrade --install -f ./values.yaml \
    --set database.password=shouldBeChanged app-dev .

helm ls