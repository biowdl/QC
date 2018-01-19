# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "wdl-tasks/fastqc.wdl" as fastqc
import "wdl-tasks/cutadapt.wdl" as cutadapt

workflow QC {
    File read1
    String outputDir
    File extractAdaptersFastqcJar
    File? read2
    String? cutadaptOutput = outputDir + "/cutadapt"
    String? fastqcOutput = outputDir + "/fastqc"
    String? extractAdaptersOutput = outputDir + "/extractAdapters"

    call fastqc.fastqc as fastqcRead1 {
        input:
            seqFile=read1,
            outdirPath=fastqcOutput
    }

    call fastqc.extractAdapters as extractAdaptersRead1 {
        input:
            extractAdaptersFastqcJar=extractAdaptersFastqcJar,

            inputFile=fastqcRead1.rawReport,
             adaptersOutputFilePath=extractAdaptersOutput + "/" + basename(read1) + ".adapters"
    }

    if (defined(read2)) {
        call fastqc.fastqc as fastqcRead2 {
            input:
                outdirPath=fastqcOutput,
                seqFile=read2
        }
        call fastqc.extractAdapters as extractAdaptersRead2 {
            input:
                extractAdaptersFastqcJar=extractAdaptersFastqcJar,
                inputFile=fastqcRead2.rawReport,
                adaptersOutputFilePath=extractAdaptersOutput + "/" + basename(read2) + ".adapters"

        }
    }

    call cutadapt.cutadapt {
        input:
            read1=read1,
            read2=read2,
            read1output=cutadaptOutput + "/cutadapt_" + basename(read1),
            read2output=cutadaptOutput + "/cutadapt_" + basename(read2),
            adapter=read_lines(extractAdaptersRead1.adapterOutputFile),
            adapterRead2=read_lines(extractAdaptersRead2.adapterOutputFile)
    }

    output {
    File read1afterQC = cutadapt.cutRead1
    File? read2afterQC = cutadapt.cutRead2
    File fastQcHtmlReport = fastqc.htmlReport
    File fastQcRawReport = fastqc.rawReport
    File cutadaptReport = cutadapt.report
    }
}