#!/usr/bin/env bash

set -eu -o pipefail

bash download_cromwell.sh
bash download_extractAdaptersFastqc.sh

for test in test/*.json
do
    echo "Running with input: $test"
    bash run_pipeline.sh $test
done
