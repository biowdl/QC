#!/usr/bin/env bash

set -e -o pipefail
conda-env create --force -f test/conda_envs/cutadapt.yml
conda-env create --force -f test/conda_envs/fastqc.yml
