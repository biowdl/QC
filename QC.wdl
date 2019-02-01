version 1.0
# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "QualityReport.wdl" as QR
import "tasks/cutadapt.wdl" as cutadapt
import "tasks/common.wdl" as common

workflow QC {
    input {
        FastqPair reads
        String outputDir
        Boolean alwaysRunAdapterClipping = false
        String sample
        String library
        String readgroup
        Int minimumReadLength = 2 # Choose 2 here to compensate for cutadapt weirdness. I.e. Having empty or non-sensical 1 base reads.
    }

    String read1outputDir = outputDir + "/QC/read1"
    String read2outputDir = outputDir + "/QC/read2"
    String read1outputDirAfterQC = outputDir + "/QCafter/read1"
    String read2outputDirAfterQC = outputDir + "/QCafter/read2"
    String adapterClippingOutputDir = outputDir + "/AdapterClipping"
    String seqstatBeforeFile = outputDir + "/QC/seqstat.json"
    String seqstatAfterFile = outputDir + "/QCafter/seqstat.json"

    if (defined(reads.R1_md5)) {
        call common.CheckFileMD5 as md5CheckR1 {
            input:
                file = reads.R1,
                md5 = select_first([reads.R1_md5])
        }
    }

    if (defined(reads.R2_md5) && defined(reads.R2)) {
        call common.CheckFileMD5 as md5CheckR2 {
            input:
                file = select_first([reads.R2]),
                md5 = select_first([reads.R2_md5])
        }
    }

    call QR.QualityReport as qualityReportRead1 {
        input:
            read = reads.R1 ,
            outputDir = read1outputDir
    }

    if (defined(reads.R2)) {
        call QR.QualityReport as qualityReportRead2 {
            input:
                read = select_first([reads.R2]),
                outputDir = read2outputDir
        }
    }


    # if no adapters are found, why run cutadapt? Unless cutadapt is used for quality trimming.
    # In which case alwaysRunCutadapt can be set to true by the user.
    Boolean runAdapterClipping = defined(qualityReportRead1.adapters) || defined(qualityReportRead2.adapters) || alwaysRunAdapterClipping

    if (runAdapterClipping) {
        if (defined(reads.R2)) {
                String read2outputPath = outputDir + "/cutadapt_" + basename(select_first([reads.R2]))
           }

        call cutadapt.Cutadapt {
            input:
                inputFastq = reads,
                read1output = outputDir + "/cutadapt_" + basename(reads.R1),
                read2output = read2outputPath,
                adapter = qualityReportRead1.adapters,
                anywhere = qualityReportRead1.contaminations,
                adapterRead2 = qualityReportRead2.adapters,
                anywhereRead2 = qualityReportRead2.contaminations,
                reportPath = outputDir + "/cutadaptReport.txt",
                minimumLength = minimumReadLength
        }

        call QR.QualityReport as qualityReportRead1after {
            input:
                read = Cutadapt.cutOutput.R1,
                outputDir = read1outputDirAfterQC
        }

        if (defined(reads.R2)) {
            call QR.QualityReport as qualityReportRead2after {
                input:
                    read = select_first([Cutadapt.cutOutput.R2]),
                    outputDir = read2outputDirAfterQC
            }
        }

    }

    output {
        FastqPair readsAfterQC = if runAdapterClipping
            then select_first([Cutadapt.cutOutput])
            else reads
    }
}



