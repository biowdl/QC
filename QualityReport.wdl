# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "tasks/fastqc.wdl" as fastqc
import "tasks/biopet.wdl" as biopet

workflow QC {
    File read
    String outputDir
    String? extractAdaptersOutput = outputDir + "/extractAdapters"
    String? fastqcOutput = outputDir + "/fastqc"
    Boolean extractAdapters

    # FastQC on read
    call fastqc.fastqc as fastqc {
        input:
            seqFile = read,
            outdirPath = select_first([fastqcOutput])
    }

    # Extract adapter sequences from the fastqc report.
    if (extractAdapters) {
        call fastqc.getConfiguration as getFastqcConfiguration {}

        call biopet.extractAdaptersFastqc as extractAdapters {
            input:
                inputFile = fastqc.rawReport,
                outputDir = select_first([extractAdaptersOutput]),
                knownAdapterFile = getFastqcConfiguration.adapterList,
                knownContamFile = getFastqcConfiguration.contaminantList
        }
        # Logic step. If no adapters are found adapterList will be null.
        # If more are found adapterList will be an array that contains at
        # least one item.
        # This is because cutadapt requires an array of at least one item.
        if (length(extractAdapters.adapterList) > 0) {
            Array[String]+ adapterList = extractAdapters.adapterList
        }
    }

    output {
        Array[String]+? adapters = adapterList
        File fastqcRawReport = fastqc.rawReport
        File fastqcSummary = fastqc.summary
        File fastqcHtmlReport = fastqc.htmlReport
        File fastqcImages = fastqc.images
    }
}