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
        # Illumina universal adapter
        Array[String] adapters = ["AGATCGGAAGAG"]
        Array[String]+? contaminations
        Int minimumReadLength = 2 # Choose 2 here to compensate for cutadapt weirdness. I.e. Having empty or non-sensical 1 base reads.

        Map[String, String] dockerTags = {"fastqc": "0.11.7--4",
            "biopet-extractadaptersfastqc": "0.2--1", "cutadapt": "1.16--py36_2"}
    }

    Boolean runAdapterClipping = length(adapters) + length(select_first(contaminations, [])) > 0

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
                adapterRead2 = adapters,
                anywhereRead2 = contaminations,
                reportPath = outputDir + "/cutadaptReport.txt",
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



