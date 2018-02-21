import "QC.wdl" as QC
import "wdl-tasks/common.wdl" as common

workflow qcMulti {
    Array[Map[String,String?]] libraries # A list of libraries with name, R1 and R2 as keys.
    String outputDir
    String? outputSuffix = ".fq.gz"
    Boolean? combineReads = false

    scatter (library in libraries) {
        call QC.QC {
            input:
                read1 = select_first([library["R1"]]),
                read2 = library["R2"],
                outputDir = outputDir + "/" + library["name"]
        }
    }

    if (select_first([combineReads])) {
    # The below code assumes that QC.read1afterQC and QC.read2afterQC are in the same order.
    call common.concatenateTextFiles as concatenateReads1 {
        input:
            fileList = QC.read1afterQC,
            combinedFilePath = outputDir + "/combinedReads1" + select_first([outputSuffix])
    }
    if (length(select_all(QC.read2afterQC)) > 0) {
        call common.concatenateTextFiles as concatenateReads2 {
        input:
            fileList = select_all(QC.read2afterQC),
            combinedFilePath = outputDir + "/combinedReads2" + select_first([outputSuffix])
        }
    }
    }
    output {
        Array[File] reads1 = QC.read1afterQC
        Array[File?] reads2 = QC.read2afterQC
        File? read1 = concatenateReads1.combinedFile
        File? read2 = concatenateReads2.combinedFile
    }
}

