# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "QualityReport.wdl" as QR
import "QualityTrim.wdl" as QT

workflow QC {
    File read1
    String outputDir
    File? read2
    String cutadaptOutput = outputDir + "/cutadapt"
    Boolean? alwaysRunQualityTrim = false

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
    Boolean runQualityTrim = defined(qualityReportRead1.adapters) || defined(qualityReportRead2.adapters) || alwaysRunQualityTrim

    if (runQualityTrim) {
        call QT.QualityTrim as QualityTrim {
            input:
                read1 = read1,
                read2 = read2,
                outputDir = outputDir + "/QualityTrim",
                end3adapterListRead1 = qualityReportRead1.adapters,
                end3adapterListRead2 = qualityReportRead2.adapters
        }

        call QR.QualityReport as qualityReportRead1after {
            input:
                read = QualityTrim.read1afterTrim,
                outputDir = outputDir + "/QCafter/read1",
                extractAdapters = false
        }
        call QR.QualityReport as qualityReportRead2after {
            input:
                read = QualityTrim.read2afterTrim,
                outputDir = outputDir + "/QCafter/read2",
                extractAdapters = false
        }
    }

    output {
        File read1afterQC = if runQualityTrim then select_first([QualityTrim.read1afterTrim]) else read1
        File? read2afterQC = if runQualityTrim then QualityTrim.read2afterTrim else read2
    }
}



