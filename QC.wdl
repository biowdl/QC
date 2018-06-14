# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "QualityReport.wdl" as QR
import "AdapterClipping.wdl" as AC

workflow QC {
    File read1
    String outputDir
    File? read2
    Boolean? alwaysRunAdapterClipping = false

    call QR.QualityReport as qualityReportRead1 {
        input:
            read = read1,
            outputDir = outputDir + "/QC/read1",
            extractAdapters = true
    }

    if (defined(read2)) {
        call QR.QualityReport as qualityReportRead2 {
            input:
                read = select_first([read2]),
                outputDir = outputDir + "/QC/read2",
                extractAdapters = true
        }
    }

    # if no adapters are found, why run cutadapt? Unless cutadapt is used for quality trimming.
    # In which case alwaysRunCutadapt can be set to true by the user.
    Boolean runAdapterClipping = defined(qualityReportRead1.adapters) || defined(qualityReportRead2.adapters) || alwaysRunAdapterClipping

    if (runAdapterClipping) {
        call AC.AdapterClipping as AdapterClipping {
            input:
                read1 = read1,
                read2 = read2,
                outputDir = outputDir + "/AdapterClipping",
                adapterListRead1 = qualityReportRead1.adapters,
                adapterListRead2 = qualityReportRead2.adapters
        }

        call QR.QualityReport as qualityReportRead1after {
            input:
                read = AdapterClipping.read1afterClipping,
                outputDir = outputDir + "/QCafter/read1",
                extractAdapters = false
        }
        if (defined(read2)) {
            call QR.QualityReport as qualityReportRead2after {
                input:
                    read = select_first([AdapterClipping.read2afterClipping]),
                    outputDir = outputDir + "/QCafter/read2",
                    extractAdapters = false
            }
        }
    }

    output {
        File read1afterQC = if runAdapterClipping then select_first([AdapterClipping.read1afterClipping]) else read1
        File? read2afterQC = if runAdapterClipping then AdapterClipping.read2afterClipping else read2
    }
}



