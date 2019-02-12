version 1.0
# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "tasks/fastqc.wdl" as fastqc
import "tasks/biopet/biopet.wdl" as biopet

workflow QualityReport {
    input {
        File read
        String outputDir
        String extractAdaptersOutput = outputDir + "/extractAdapters"
        String fastqcOutput = outputDir + "/fastqc"
        Boolean extractAdapters = true

        Map[String, String] dockerTags = {"fastqc": "0.11.7--4",
            "biopet-extractadaptersfastqc": "0.2--1"}
    }

    # FastQC on read
    call fastqc.Fastqc as Fastqc {
        input:
            seqFile = read,
            outdirPath = fastqcOutput,
            dockerTag = dockerTags["fastqc"]
    }

    # Extract adapter sequences from the fastqc report.
    if (extractAdapters) {
        call fastqc.GetConfiguration as getFastqcConfiguration {
            input:
                dockerTag = dockerTags["fastqc"]
        }

        call biopet.ExtractAdaptersFastqc as extractAdaptersTask {
            input:
                inputFile = Fastqc.rawReport,
                outputDir = extractAdaptersOutput,
                knownAdapterFile = getFastqcConfiguration.adapterList,
                knownContamFile = getFastqcConfiguration.contaminantList,
                dockerTag = dockerTags["biopet-extractadaptersfastqc"]
        }
        # Logic step. If no adapters are found adapterList will be null.
        # If more are found adapterList will be an array that contains at
        # least one item.
        # This is because cutadapt requires an array of at least one item.
        if (length(extractAdaptersTask.adapterList) > 0) {
            Array[String]+ adapterList = extractAdaptersTask.adapterList
        }
        if (length(extractAdaptersTask.contamsList) > 0) {
            Array[String]+ contaminationsList = extractAdaptersTask.contamsList
        }
    }

    output {
        Array[String]+? adapters = adapterList
        Array[String]+? contaminations = contaminationsList
        File fastqcRawReport = Fastqc.rawReport
        File fastqcSummary = Fastqc.summary
        File fastqcHtmlReport = Fastqc.htmlReport
        Array[File] fastqcImages = Fastqc.images
    }
}