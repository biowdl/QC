version 1.0
# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "QualityReport.wdl" as QR
import "AdapterClipping.wdl" as AC
import "tasks/biopet/seqstat.wdl" as seqstat
import "tasks/biopet.wdl" as biopet

workflow QC {
    input {
        File read1
        String outputDir
        File? read2
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
            fastq1 = read1,
            fastq2 = read2
    }

    call QR.QualityReport as qualityReportRead1 {
        input:
            read = ValidateFastq.validatedFastq1 ,
            outputDir = read1outputDir,
            extractAdapters = true
    }

    if (defined(read2)) {
        call QR.QualityReport as qualityReportRead2 {
            input:
                read = select_first([ValidateFastq.validatedFastq2]),
                outputDir = read2outputDir,
                extractAdapters = true
        }
    }

    # Seqstat on reads
    call seqstat.Generate as seqstat {
        input:
            fastqR1 = ValidateFastq.validatedFastq1,
            fastqR2 = ValidateFastq.validatedFastq2,
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
                read1 = ValidateFastq.validatedFastq1,
                read2 = ValidateFastq.validatedFastq2,
                outputDir = adapterClippingOutputDir,
                adapterListRead1 = qualityReportRead1.adapters,
                adapterListRead2 = qualityReportRead2.adapters,
                contaminationsListRead1 = qualityReportRead1.contaminations,
                contaminationsListRead2 = qualityReportRead2.contaminations
        }

        call QR.QualityReport as qualityReportRead1after {
            input:
                read = AdapterClipping.read1afterClipping,
                outputDir = read1outputDirAfterQC
        }

        if (defined(read2)) {
            call QR.QualityReport as qualityReportRead2after {
                input:
                    read = select_first([AdapterClipping.read2afterClipping]),
                    outputDir = read2outputDirAfterQC
            }
        }

        call seqstat.Generate as seqstatAfter {
            input:
                fastqR1 = AdapterClipping.read1afterClipping,
                fastqR2 = AdapterClipping.read2afterClipping,
                outputFile = seqstatAfterFile,
                sample = sample,
                library = library,
                readgroup = readgroup
        }
    }

    output {
        File read1afterQC = if runAdapterClipping
            then select_first([AdapterClipping.read1afterClipping])
            else ValidateFastq.validatedFastq1
        File? read2afterQC = if runAdapterClipping
            then AdapterClipping.read2afterClipping
            else ValidateFastq.validatedFastq2
    }
}



