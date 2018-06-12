# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "tasks/fastqc.wdl" as fastqc
import "tasks/biopet.wdl" as biopet

workflow QC {
    File read1
    String outputDir
    File? extractAdaptersFastqcJar
    File? read2
    String? extractAdaptersOutput = outputDir + "/extractAdapters"
    Boolean extractAdapters

    # Run this step to get the known adapter and contaminant list to extract
    # the adapters later.
    call fastqc.getConfiguration as getFastqcConfiguration {}

    # FastQC on Read1
    call fastqc.fastqc as fastqcRead1 {
        input:
            seqFile = read1,
            outdirPath = outputDir + "/fastqc/R1"
    }

    # Extract adapter sequences from the fastqc report.
    if (extractAdapters) {
        call biopet.extractAdaptersFastqc as extractAdaptersRead1 {
            input:
                toolJar = extractAdaptersFastqcJar,
                inputFile = fastqcRead1.rawReport,
                outputDir = select_first([extractAdaptersOutput]) + "/R1",
                knownAdapterFile = getFastqcConfiguration.adapterList,
                knownContamFile = getFastqcConfiguration.contaminantList
        }
        # Logic step. If no adapters are found adapterListRead1 will be null.
        # If more are found adapterListRead1 will be an array that contains at
        # least one item.
        # This is because cutadapt requires an array of at least one item.
        if (length(extractAdaptersRead1.adapterList) > 0) {
            Array[String]+ adapterListRead1 = extractAdaptersRead1.adapterList
        }
    }




    # For paired-end also perform fastqc on read2. Steps are the same as on read 1.
    if (defined(read2)) {
        call fastqc.fastqc as fastqcRead2 {
            input:
                 outdirPath = outputDir + "/fastqc/R2",
                 seqFile = select_first([read2])
        }

        if (extractAdapters) {
            call biopet.extractAdaptersFastqc as extractAdaptersRead2 {
                input:
                    toolJar = extractAdaptersFastqcJar,
                    inputFile = fastqcRead2.rawReport,
                    outputDir = select_first([extractAdaptersOutput]) + "/R2",
                    knownAdapterFile = getFastqcConfiguration.adapterList,
                    knownContamFile = getFastqcConfiguration.contaminantList
            }
            if (length(extractAdaptersRead2.adapterList) > 0) {
                Array[String]+ adapterListRead2 = extractAdaptersRead2.adapterList
        }
        }
    }


    output {
        Array[String]+? adaptersRead1 = adapterListRead1
        Array[String]+? adaptersRead2 = adapterListRead2
        File
    }
}