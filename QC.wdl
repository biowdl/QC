version 1.0
# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "QualityReport.wdl" as QR
import "AdapterClipping.wdl" as AC
import "tasks/common.wdl" as common

workflow QC {
    input {
        FastqPair reads
        String outputDir
        Boolean alwaysRunAdapterClipping = false
        String sample
        String library
        String readgroup
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
        call AC.AdapterClipping as AdapterClipping {
            input:
                reads = reads,
                outputDir = adapterClippingOutputDir,
                adapterListRead1 = qualityReportRead1.adapters,
                adapterListRead2 = qualityReportRead2.adapters,
                contaminationsListRead1 = qualityReportRead1.contaminations,
                contaminationsListRead2 = qualityReportRead2.contaminations
        }

        call QR.QualityReport as qualityReportRead1after {
            input:
                read = AdapterClipping.afterClipping.R1,
                outputDir = read1outputDirAfterQC
        }

        if (defined(reads.R2)) {
            call QR.QualityReport as qualityReportRead2after {
                input:
                    read = select_first([AdapterClipping.afterClipping.R2]),
                    outputDir = read2outputDirAfterQC
            }
        }

    }

    output {
        FastqPair readsAfterQC = if runAdapterClipping
            then select_first([AdapterClipping.afterClipping])
            else reads
    }
}



