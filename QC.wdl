version 1.0
# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "QualityReport.wdl" as QR
import "tasks/cutadapt.wdl" as cutadapt
import "tasks/common.wdl" as common

workflow QC {
    input {
        File read1
        File? read2
        String outputDir
        Boolean alwaysRunAdapterClipping = false
        Int minimumReadLength = 2 # Choose 2 here to compensate for cutadapt weirdness. I.e. Having empty or non-sensical 1 base reads.
    }

    String read1outputDir = outputDir + "/QC/read1"
    String read2outputDir = outputDir + "/QC/read2"
    String read1outputDirAfterQC = outputDir + "/QCafter/read1"
    String read2outputDirAfterQC = outputDir + "/QCafter/read2"
    String adapterClippingOutputDir = outputDir + "/AdapterClipping"
    String seqstatBeforeFile = outputDir + "/QC/seqstat.json"
    String seqstatAfterFile = outputDir + "/QCafter/seqstat.json"

    call QR.QualityReport as qualityReportRead1 {
        input:
            read = read1,
            outputDir = read1outputDir
    }

    if (defined(read2)) {
        call QR.QualityReport as qualityReportRead2 {
            input:
                read = select_first([read2]),
                outputDir = read2outputDir
        }
    }

    # if no adapters are found, why run cutadapt? Unless cutadapt is used for quality trimming.
    # In which case alwaysRunCutadapt can be set to true by the user.
    Boolean runAdapterClipping = defined(qualityReportRead1.adapters) || defined(qualityReportRead2.adapters) || alwaysRunAdapterClipping

    if (runAdapterClipping) {
        if (defined(read2)) {
                String read2outputPath = outputDir + "/AdapterClipping/cutadapt_" + basename(select_first([read2]))
        }

        call cutadapt.Cutadapt as Cutadapt {
            input:
                read1 = read1,
                read2 = read2,
                read1output = outputDir + "/AdapterClipping/cutadapt_" + basename(read1),
                read2output = read2outputPath,
                adapter = qualityReportRead1.adapters,
                anywhere = qualityReportRead1.contaminations,
                adapterRead2 = qualityReportRead2.adapters,
                anywhereRead2 = qualityReportRead2.contaminations,
                reportPath = outputDir + "/AdapterClipping/cutadaptReport.txt",
                minimumLength = minimumReadLength
        }

        call QR.QualityReport as qualityReportRead1after {
            input:
                read = Cutadapt.cutRead1,
                outputDir = read1outputDirAfterQC
        }

        if (defined(read2)) {
            call QR.QualityReport as qualityReportRead2after {
                input:
                    read = select_first([Cutadapt.cutRead2]),
                    outputDir = read2outputDirAfterQC
            }
        }

    }

    output {
        File qcRead1 = if runAdapterClipping then select_first([Cutadapt.cutRead1]) else read1
        File? qcRead2 = if runAdapterClipping then select_first([Cutadapt.cutRead2]) else read2
    }
 }



