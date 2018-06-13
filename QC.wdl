# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "QualityReport.wdl" as QR

workflow QC {
    File read1
    String outputDir
    File? read2
    String cutadaptOutput = outputDir + "/cutadapt"
    Boolean? alwaysRunCutadapt = false

    call QR.QualityReport as qualityReportRead1 {
        input:
            read = read1,
            outputDir = outputDir + "/QC/read1",
            extractAdapters = true
    }

    if (defined(read2)) {
        call QR.QualityReport as qualityReportRead2 {
            input:
                read = read2,
                outputDir = outputDir + "/QC/read2",
                extractAdapters = true
        }
    }

    # if no adapters are found, why run cutadapt? Unless cutadapt is used for quality trimming.
    # In which case alwaysRunCutadapt can be set to true by the user.
    Boolean runQualityTrim = defined(adapterListRead1) || defined(adapterListRead2) || alwaysRunCutadapt


    output {
        File read1afterQC = if runCutadapt then select_first([cutadapt.cutRead1]) else read1
        File? read2afterQC = if runCutadapt then cutadapt.cutRead2 else read2
        File? cutadaptReport = cutadapt.report
    }
}



