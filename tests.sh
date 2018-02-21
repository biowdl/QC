#!/usr/bin/env bash

set -eu -o pipefail

bash download_cromwell.sh
bash download_extractAdaptersFastqc.sh
bash create_environments.sh

for test in test/{single,singlegz,paired,pairedgz}.json
do
    echo "Running with input: $test"
    bash run_QC.sh $test
done
