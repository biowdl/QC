version 1.0
# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "tasks/cutadapt.wdl" as cutadapt
import "tasks/fastqc.wdl" as fastqc

workflow QC {
    input {
        File read1
        File? read2
        String outputDir = "."
        String? adapterForward = "AGATCGGAAGAG"  # Illumina universal adapter
        String? adapterReverse
        Array[String]+? contaminations
        # A readgroupName so cutadapt creates a unique report name. This is useful if all the QC files are dumped in one folder.
        String readgroupName = sub(basename(read1),"(\.fq)?(\.fastq)?(\.gz)?", "")
        Map[String, String] dockerImages = {
        "fastqc": "quay.io/biocontainers/fastqc:0.11.7--4",
        "cutadapt": "quay.io/biocontainers/cutadapt:2.4--py37h14c3975_0"
        }
        # Only run cutadapt if it makes sense.
        Boolean runAdapterClipping = defined(adapterForward) || defined(adapterReverse) || length(select_first([contaminations, []])) > 0
    }

    # If read2 is defined but a reverse adapter is not given we take the illumina universal adapter.
    # If read2 is defined and a reverse adapter is given we use that
    # If read2 is not defined we set it empty.
    Array[String] adapterReverseDefault = if defined(read2) then [select_first([adapterReverse, "AGATCGGAAGAG"])] else []

    call fastqc.Fastqc as FastqcRead1 {
        input:
            seqFile = read1,
            outdirPath = outputDir + "/",
            dockerImage = dockerImages["fastqc"]
    }

    if (defined(read2)) {
        call fastqc.Fastqc as FastqcRead2 {
            input:
                seqFile = select_first([read2]),
                outdirPath = outputDir + "/",
                dockerImage = dockerImages["fastqc"]
        }
        String read2outputPath = outputDir + "/cutadapt_" + basename(select_first([read2]))
    }

    if (runAdapterClipping) {
        call cutadapt.Cutadapt as Cutadapt {
            input:
                read1 = read1,
                read2 = read2,
                read1output = outputDir + "/cutadapt_" + basename(read1),
                read2output = read2outputPath,
                adapter = select_all([adapterForward]),
                anywhere = contaminations,
                adapterRead2 = adapterReverseDefault,
                anywhereRead2 = if defined(read2) then contaminations else read2,
                reportPath = outputDir + "/" + readgroupName +  "_cutadapt_report.txt",
                dockerImage = dockerImages["cutadapt"]
        }

        call fastqc.Fastqc as FastqcRead1After {
            input:
                seqFile = Cutadapt.cutRead1,
                outdirPath = outputDir + "/",
                dockerImage = dockerImages["fastqc"]
        }

        if (defined(read2)) {
            call fastqc.Fastqc as FastqcRead2After {
                input:
                    seqFile = select_first([Cutadapt.cutRead2]),
                    outdirPath = outputDir + "/",
                    dockerImage = dockerImages["fastqc"]
            }
        }
    }

    output {
        File qcRead1 = if runAdapterClipping then select_first([Cutadapt.cutRead1]) else read1
        File? qcRead2 = if runAdapterClipping then Cutadapt.cutRead2 else read2
        File read1htmlReport = FastqcRead1.htmlReport
        File read1reportZip = FastqcRead1.reportZip
        File? read2htmlReport = FastqcRead2.htmlReport
        File? read2reportZip = FastqcRead2.reportZip
        File? read1afterHtmlReport = FastqcRead1After.htmlReport
        File? read1afterReportZip = FastqcRead1After.reportZip
        File? read2afterHtmlReport = FastqcRead2After.htmlReport
        File? read2afterReportZip = FastqcRead2After.reportZip
        File? cutadaptReport = Cutadapt.report
        Array[File] reports = select_all([
            read1htmlReport,
            read1reportZip,
            read2htmlReport,
            read2reportZip,
            read1afterHtmlReport,
            read1afterReportZip,
            read2afterHtmlReport,
            read2afterReportZip,
            cutadaptReport
            ])
    }
 }



