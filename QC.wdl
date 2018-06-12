# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "tasks/fastqc.wdl" as fastqc
import "tasks/cutadapt.wdl" as cutadapt
import "tasks/biopet.wdl" as biopet
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



