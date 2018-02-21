#!/usr/bin/env bash

set -eu -o pipefail

cromwell_version=30.1
java -jar cromwell-$cromwell_version.jar run -i $1 QC.wdl