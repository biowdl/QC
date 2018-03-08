# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "wdl-tasks/fastqc.wdl" as fastqc
import "wdl-tasks/cutadapt.wdl" as cutadapt
import "wdl-tasks/bioconda.wdl" as bioconda

workflow QC {
    File read1
    String outputDir
    File extractAdaptersFastqcJar
    File? read2
    String cutadaptOutput = outputDir + "/cutadapt"
    String? extractAdaptersOutput = outputDir + "/extractAdapters"
    Boolean? alwaysRunCutadapt = false

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
    call fastqc.extractAdapters as extractAdaptersRead1 {
        input:
            extractAdaptersFastqcJar = extractAdaptersFastqcJar,
            inputFile = fastqcRead1.rawReport,
            outputDir = select_first([extractAdaptersOutput]),
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

    # For paired-end also perform fastqc on read2. Steps are the same as on read 1.
    if (defined(read2)) {
        call fastqc.fastqc as fastqcRead2 {
            input:
                 outdirPath = outputDir + "/fastqc/R2",
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

        # Because it is placed inside the if block read2outputPath is optional. It
        # will default to null if read2 is not used. This is necessary to run
        # cutadapt without a read2 output if there is no read2.
        String read2outputPath = cutadaptOutput + "/cutadapt_" + basename(select_first([read2]))
    }

    # if no adapters are found, why run cutadapt? Unless cutadapt is used for quality trimming.
    # In which case alwaysRunCutadapt can be set to true by the user.
    Boolean runCutadapt = defined(adapterListRead1) || defined(adapterListRead2) || alwaysRunCutadapt

    if (runCutadapt) {
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
    }

    output {
        File read1afterQC = if runCutadapt then select_first([cutadapt.cutRead1]) else read1
        File? read2afterQC = if runCutadapt then cutadapt.cutRead2 else read2
        File? cutadaptReport = cutadapt.report
    }
}



