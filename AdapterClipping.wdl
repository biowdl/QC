# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "tasks/cutadapt.wdl" as cutadapt
import "tasks/biopet.wdl" as biopet

workflow AdapterClipping {
    File read1
    File? read2
    String outputDir
    Array[String]+? adapterListRead1
    Array[String]+? adapterListRead2


    if (defined(read2)) {
        String read2outputPath = outputDir + "/cutadapt_" + basename(select_first([read2]))
    }

    call cutadapt.cutadapt {
        input:
            read1 = read1,
            read2 = read2,
            read1output = outputDir + "/cutadapt_" + basename(read1),
            read2output = read2outputPath,
            adapter = adapterListRead1,
            adapterRead2 = adapterListRead2,
            reportPath = outputDir + "/cutadaptReport.txt"
    }

    call biopet.ValidateFastq as ValidateFastq {
      input:
        fastq1 = cutadapt.cutRead1,
        fastq2 = cutadapt.cutRead2
    }
    output {
        File read1afterClipping = cutadapt.cutRead1
        File? read2afterClipping = cutadapt.cutRead2
        File cutadaptReport = cutadapt.report
        File validationReport = ValidateFastq.stderr
    }
}
