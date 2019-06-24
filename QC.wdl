version 1.0
# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "tasks/cutadapt.wdl" as cutadapt
import "tasks/common.wdl" as common
import "tasks/fastqc.wdl" as fastqc

workflow QC {
    input {
        File read1
        File? read2
        String outputDir
        # Adapters and contaminations are optional and need at least one item if defined.
        # This is necessary so no empty flags are used in cutadapt.
        # FIXME: Subworkflow inputs cannot be overridden using Cromwell. This
        # FIXME: is necessary for this workflow to function properly as a subworkflow.
        #Array[String]+? adapters = ["AGATCGGAAGAG"]  # Illumina universal adapter
        #Array[String]+? contaminations

        # A readgroupName so cutadapt creates a unique report name. This is useful if all the QC files are dumped in one folder.
        String readgroupName = sub(basename(read1),"(\.fq)?(\.fastq)?(\.gz)?", "")
        Map[String, String] dockerImages = {
        "fastqc": "quay.io/biocontainers/fastqc:0.11.7--4",
        "cutadapt": "quay.io/biocontainers/cutadapt:2.3--py36h14c3975_0"
        }
    }

    # FIXME: Only makes sense with workflow inputs. Cromwell should be fixed.
    #Boolean runAdapterClipping = length(select_first([adapters, []])) + length(select_first([contaminations, []])) > 0
    Boolean runAdapterClipping = true

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
                # Fixme: Adapters and contaminations now disabled so they can be user overridable. Cromwell should allow overriding subworkflow defaults.
                #adapter = adapters,
                #anywhere = contaminations,
                # Fixme: Read2 is used here as `None` or JsNull. None will exist in WDL versions 1.1 and higher
                #adapterRead2 = if defined(read2) then adapters else read2,
                #anywhereRead2 = if defined(read2) then contaminations else read2,
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



