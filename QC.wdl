version 1.0
# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "QualityReport.wdl" as QR
import "AdapterClipping.wdl" as AC
import "ValidateFastqFiles.wdl" as validate

workflow QC {
    input {
        File read1
        String outputDir
        File? read2
        Boolean? alwaysRunAdapterClipping = false
    }

    String read1outputDir = outputDir + "/QC/read1"
    String read2outputDir = outputDir + "/QC/read2"
    String read1outputDirAfterQC = outputDir + "/QCafter/read1"
    String read2outputDirAfterQC = outputDir + "/QCafter/read2"
    String adapterClippingOutputDir = outputDir + "/AdapterClipping"
    call validate.ValidateFastqFiles as validated {
        input:
            read1 = read1,
            read2 = read2

    }

    call QR.QualityReport as qualityReportRead1 {
        input:
            read = validated.validatedRead1,
            outputDir = read1outputDir,
            extractAdapters = true
    }

    if (defined(read2)) {
        call QR.QualityReport as qualityReportRead2 {
            input:
                read = select_first([validated.validatedRead2]),
                outputDir = read2outputDir,
                extractAdapters = true
        }
    }

    # if no adapters are found, why run cutadapt? Unless cutadapt is used for quality trimming.
    # In which case alwaysRunCutadapt can be set to true by the user.
    Boolean runAdapterClipping = defined(qualityReportRead1.adapters) || defined(qualityReportRead2.adapters) || alwaysRunAdapterClipping

    if (runAdapterClipping) {
        call AC.AdapterClipping as AdapterClipping {
            input:
                read1 = validated.validatedRead1,
                read2 = validated.validatedRead2,
                outputDir = adapterClippingOutputDir,
                adapterListRead1 = qualityReportRead1.adapters,
                adapterListRead2 = qualityReportRead2.adapters
        }

        call QR.QualityReport as qualityReportRead1after {
            input:
                read = AdapterClipping.read1afterClipping,
                outputDir = read1outputDirAfterQC,
                extractAdapters = false
        }
        if (defined(read2)) {
            call QR.QualityReport as qualityReportRead2after {
                input:
                    read = select_first([AdapterClipping.read2afterClipping]),
                    outputDir = read2outputDirAfterQC,
                    extractAdapters = false
            }
        }
    }

    output {
        File read1afterQC = if runAdapterClipping then select_first([AdapterClipping.read1afterClipping]) else validated.validatedRead1
        File? read2afterQC = if runAdapterClipping then AdapterClipping.read2afterClipping else validated.validatedRead2
    }
}



