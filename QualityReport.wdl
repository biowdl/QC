version 1.0

# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "tasks/fastqc.wdl" as fastqc
import "tasks/biopet.wdl" as biopet

workflow QualityReport {
    input {
        File read
        String outputDir
        String extractAdaptersOutput = outputDir + "/extractAdapters"
        String fastqcOutput = outputDir + "/fastqc"
        Boolean extractAdapters = false
    }

    # FastQC on read
    call fastqc.Fastqc as fastqc {
        input:
            seqFile = read,
            outdirPath = fastqcOutput
    }

    # Seqstat on read
    call biopet.Seqstat as seqstat {
        input:
            fastq = read,
            outputFile = outputDir + "/seqstat.json"
    }

    # Extract adapter sequences from the fastqc report.
    if (extractAdapters) {
        call fastqc.GetConfiguration as getFastqcConfiguration {
            input:
        }

        call biopet.ExtractAdaptersFastqc as extractAdaptersTask {
            input:
                inputFile = fastqc.rawReport,
                outputDir = extractAdaptersOutput,
                knownAdapterFile = getFastqcConfiguration.adapterList,
                knownContamFile = getFastqcConfiguration.contaminantList
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
        File fastqcRawReport = fastqc.rawReport
        File fastqcSummary = fastqc.summary
        File fastqcHtmlReport = fastqc.htmlReport
        Array[File] fastqcImages = fastqc.images
        File seqstatJson = seqstat.json
    }
}