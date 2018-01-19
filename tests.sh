#!/usr/bin/env bash

bash download_cromwell.sh

for test in test/*.json
do
    echo "Running with input: $test"
    bash run_pipeline.sh $test
done
