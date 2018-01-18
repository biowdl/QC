# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "wdl-tasks/fastqc.wdl" as fastqc
import "wdl-tasks/cutadapt.wdl" as cutadapt

workflow QC {
    File read1
    File? read2

    call fastqc.fastqc {
        input:
            read1=read1,
            read2=read2
    }

    call fastqc.extractAdapters {
        input:
            fastqcRawReport=fastqc.rawReport
    }

    call cutadapt.cutadapt {
        input:
            read1=read1,
            read2=read2,
            adapterList=extractAdapters.adapterList
    }

    output {
    File read1afterQC = cutadapt.cutRead1
    File? read2afterQC = cutadapt.cutRead2
    File fastQcHtmlReport = fastqc.htmlReport
    File fastQcRawReport = fastqc.rawReport
    File cutadaptReport = cutadapt.report
    }
}