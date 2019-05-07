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
        Array[String]+? adapters = ["AGATCGGAAGAG"]  # Illumina universal adapter
        Array[String]+? contaminations
        Int minimumReadLength = 2 # Choose 2 here to compensate for cutadapt weirdness. I.e. Having empty or non-sensical 1 base reads.
        # A readgroupName so cutadapt creates a unique report name. This is useful if all the QC files are dumped in one folder.
        String readgroupName = sub(basename(read1),"(\.fq)?(\.fastq)?(\.gz)?", "")
        Map[String, String] dockerTags = {"fastqc": "0.11.7--4",
            "biopet-extractadaptersfastqc": "0.2--1", "cutadapt": "1.16--py36_2"}
    }

    Boolean runAdapterClipping = length(select_first([adapters, []])) + length(select_first([contaminations, []])) > 0

    call fastqc.Fastqc as FastqcRead1 {
        input:
            seqFile = read1,
            outdirPath = outputDir + "/",
            dockerTag = dockerTags["fastqc"]
    }

    if (defined(read2)) {
        call fastqc.Fastqc as FastqcRead2 {
            input:
                seqFile = select_first([read2]),
                outdirPath = outputDir + "/",
                dockerTag = dockerTags["fastqc"]
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
                adapter = adapters,
                anywhere = contaminations,
                # Fixme: Read2 is used here as `None` or JsNull. None will exist in WDL versions 1.1 and higher
                adapterRead2 = if defined(read2) then adapters else read2,
                anywhereRead2 = if defined(read2) then contaminations else read2,
                reportPath = outputDir + "/" + readgroupName +  "_cutadapt_report.txt",
                minimumLength = minimumReadLength,
                dockerTag = dockerTags["cutadapt"]
        }

        call fastqc.Fastqc as FastqcRead1After {
            input:
                seqFile = Cutadapt.cutRead1,
                outdirPath = outputDir + "/",
                dockerTag = dockerTags["fastqc"]
        }

        if (defined(read2)) {
            call fastqc.Fastqc as FastqcRead2After {
                input:
                    seqFile = select_first([Cutadapt.cutRead2]),
                    outdirPath = outputDir + "/",
                    dockerTag = dockerTags["fastqc"]
            }
        }
    }

    output {
        File qcRead1 = if runAdapterClipping then select_first([Cutadapt.cutRead1]) else read1
        File? qcRead2 = if runAdapterClipping then Cutadapt.cutRead2 else read2
    }
 }



