# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "wdl-tasks/fastqc.wdl" as fastqc
import "wdl-tasks/cutadapt.wdl" as cutadapt
import "wdl-tasks/bioconda.wdl" as bioconda

workflow QC {
    File read1
    String outputDir
    File extractAdaptersFastqcJar
    Map[String,String?] preCommands
    File? read2
    String? cutadaptOutput = outputDir + "/cutadapt"
    String? fastqcOutput = outputDir + "/fastqc"
    String? extractAdaptersOutput = outputDir + "/extractAdapters"

    call fastqc.getConfiguration as getFastqcConfiguration {
        input:
            preCommand = preCommands["fastqc"]
    }

    call fastqc.fastqc as fastqcRead1 {
        input:
            preCommand = preCommands["fastqc"],
            seqFile = read1,
            outdirPath = select_first([fastqcOutput])
    }

    call fastqc.extractAdapters as extractAdaptersRead1 {
        input:
            extractAdaptersFastqcJar = extractAdaptersFastqcJar,
            inputFile = fastqcRead1.rawReport,
            outputDir = select_first([extractAdaptersOutput]),
            knownAdapterFile = getFastqcConfiguration.adapterList,
            knownContamFile = getFastqcConfiguration.contaminantList
    }

    if (length(extractAdaptersRead1.adapterList) > 0) {
        Array[String]+ adapterListRead1 = extractAdaptersRead1.adapterList
    }

    if (defined(read2)) {
        call fastqc.fastqc as fastqcRead2 {
            input:
                 preCommand = preCommands["fastqc"],
                 outdirPath = select_first([fastqcOutput]),
                 seqFile = select_first([read2])
        }
        call fastqc.extractAdapters as extractAdaptersRead2 {
            input:
                extractAdaptersFastqcJar = extractAdaptersFastqcJar,
                inputFile = fastqcRead2.rawReport,
                outputDir = select_first([extractAdaptersOutput]),
                knownAdapterFile = getFastqcConfiguration.adapterList,
                knownContamFile = getFastqcConfiguration.contaminantList
        }
        if (length(extractAdaptersRead2.adapterList) > 0) {
            Array[String]+ adapterListRead2 = extractAdaptersRead2.adapterList
        }
        String read2outputPath = cutadaptOutput + "/cutadapt_" + basename(select_first([read2]))
    }

    call cutadapt.cutadapt {
        input:
            preCommand = preCommands["cutadapt"],
            read1 = read1,
            read2 = read2,
            read1output = cutadaptOutput + "/cutadapt_" + basename(read1),
            read2output = read2outputPath,
            adapter = adapterListRead1,
            adapterRead2 = adapterListRead2,
            reportPath = cutadaptOutput + "/report.txt"
    }

    output {
    File read1afterQC = cutadapt.cutRead1
    File? read2afterQC = cutadapt.cutRead2
    File cutadaptReport = cutadapt.report
    }
}



