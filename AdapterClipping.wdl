version 1.0
# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "tasks/cutadapt.wdl" as cutadapt
import "tasks/biopet/biopet.wdl" as biopet
import "tasks/common.wdl" as common

workflow AdapterClipping {
    input {
        FastqPair reads
        String outputDir
        Array[String]+? adapterListRead1
        Array[String]+? adapterListRead2
        Array[String]+? contaminationsListRead1
        Array[String]+? contaminationsListRead2
        Int minimumReadLength = 2 # Choose 2 here to compensate for cutadapt weirdness. I.e. Having empty or non-sensical 1 base reads.
    }

    if (defined(reads.R2)) {
        String read2outputPath = outputDir + "/cutadapt_" + basename(select_first([reads.R2]))
    }

    call cutadapt.Cutadapt {
        input:
            inputFastq = reads,
            read1output = outputDir + "/cutadapt_" + basename(reads.R1),
            read2output = read2outputPath,
            adapter = adapterListRead1,
            anywhere = contaminationsListRead1,
            adapterRead2 = adapterListRead2,
            anywhereRead2 = contaminationsListRead2,
            reportPath = outputDir + "/cutadaptReport.txt",
            minimumLength = minimumReadLength
    }

    call biopet.ValidateFastq as ValidateFastq {
      input:
        inputFastq = Cutadapt.cutOutput
    }

    output {
        # Make sure reads are valid before passing them.
        FastqPair afterClipping = ValidateFastq.validatedFastq
        File cutadaptReport = Cutadapt.report
        File validationReport = ValidateFastq.stderr
    }
}
