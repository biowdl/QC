version 1.0
# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "tasks/biopet.wdl" as biopet

workflow ValidateFastqFiles {
    input {
        File read1
        File? read2
    }
    call biopet.ValidateFastq {
        input:
            fastq1 = read1,
            fastq2 = read2
    }

    output {
        File validatedRead1 = read1
        File? validatedRead2 = read2
        File validationReport = ValidateFastq.stderr
    }
}