version 1.0
# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "QualityReport.wdl" as QR
import "AdapterClipping.wdl" as AC
import "tasks/biopet/seqstat.wdl" as seqstat
import "tasks/biopet/biopet.wdl" as biopet
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

    call biopet.ValidateFastq as ValidateFastq {
        input:
            inputFastq = reads
    }

    call QR.QualityReport as qualityReportRead1 {
        input:
            read = ValidateFastq.validatedFastq.R1 ,
            outputDir = read1outputDir
    }

    if (defined(reads.R2)) {
        call QR.QualityReport as qualityReportRead2 {
            input:
                read = select_first([ValidateFastq.validatedFastq.R2]),
                outputDir = read2outputDir
        }
    }

    # Seqstat on reads
    call seqstat.Generate as seqstat {
        input:
            fastq = ValidateFastq.validatedFastq,
            outputFile = seqstatBeforeFile,
            sample = sample,
            library = library,
            readgroup = readgroup
    }


    # if no adapters are found, why run cutadapt? Unless cutadapt is used for quality trimming.
    # In which case alwaysRunCutadapt can be set to true by the user.
    Boolean runAdapterClipping = defined(qualityReportRead1.adapters) || defined(qualityReportRead2.adapters) || alwaysRunAdapterClipping

    if (runAdapterClipping) {
        call AC.AdapterClipping as AdapterClipping {
            input:
                reads = ValidateFastq.validatedFastq,
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

        call seqstat.Generate as seqstatAfter {
            input:
                fastq = AdapterClipping.afterClipping,
                outputFile = seqstatAfterFile,
                sample = sample,
                library = library,
                readgroup = readgroup
        }
    }

    output {
        FastqPair read1afterQC = if runAdapterClipping
            then select_first([AdapterClipping.afterClipping])
            else ValidateFastq.validatedFastq
    }
}



