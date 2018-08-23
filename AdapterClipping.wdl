version 1.0
# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "tasks/cutadapt.wdl" as cutadapt
import "tasks/biopet.wdl" as biopet

workflow AdapterClipping {
    input {
        File read1
        File? read2
        String outputDir
        Array[String]+? adapterListRead1
        Array[String]+? adapterListRead2
        Array[String]+? contaminationsListRead1
        Array[String]+? contaminationsListRead2
        Int minimumReadLength = 2 # Choose 2 here to compensate for cutadapt weirdness. I.e. Having empty or non-sensical 1 base reads.
    }

    if (defined(read2)) {
        String read2outputPath = outputDir + "/cutadapt_" + basename(select_first([read2]))
    }

    call cutadapt.Cutadapt {
        input:
            read1 = read1,
            read2 = read2,
            read1output = outputDir + "/cutadapt_" + basename(read1),
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
        fastq1 = Cutadapt.cutRead1,
        fastq2 = Cutadapt.cutRead2
    }

    output {
        # Make sure reads are valid before passing them.
        File read1afterClipping = ValidateFastq.validatedFastq1
        File? read2afterClipping = ValidateFastq.validatedFastq2
        File cutadaptReport = Cutadapt.report
        File validationReport = ValidateFastq.stderr
    }
}
