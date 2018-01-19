# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "wdl-tasks/fastqc.wdl" as fastqc
import "wdl-tasks/cutadapt.wdl" as cutadapt
import "wdl-tasks/bioconda.wdl" as bioconda

workflow QC {
    File read1
    String outputDir
    File extractAdaptersFastqcJar
    File? read2
    String? cutadaptOutput = outputDir + "/cutadapt"
    String? fastqcOutput = outputDir + "/fastqc"
    String? extractAdaptersOutput = outputDir + "/extractAdapters"

    call bioconda.installPrefix as installFastqc {
        input:
            prefix= "conda/fastqc",
            requirements=["fastqc"]
    }

    call bioconda.installPrefix as installCutadapt {
        input:
            prefix="conda/cutadapt",
            requirements=["cutadapt"]
    }

    call fastqc.fastqc as fastqcRead1 {
        input:
            condaEnv=installFastqc.condaEnvPath,
            seqFile=read1,
            outdirPath=select_first([fastqcOutput])
    }

    call fastqc.extractAdapters as extractAdaptersRead1 {
        input:
            extractAdaptersFastqcJar=extractAdaptersFastqcJar,
            inputFile=fastqcRead1.rawReport,
            outputDir=select_first([extractAdaptersOutput])
    }

    if (defined(read2)) {
        call fastqc.fastqc as fastqcRead2 {
            input:
                condaEnv=installFastqc.condaEnvPath,
                 outdirPath=select_first([fastqcOutput]),
                 seqFile=select_first([read2])
        }
        call fastqc.extractAdapters as extractAdaptersRead2 {
            input:
                extractAdaptersFastqcJar=extractAdaptersFastqcJar,
                inputFile=fastqcRead2.rawReport,
                outputDir=select_first([extractAdaptersOutput])
        }
    }

    call cutadapt.cutadapt {
        input:
            condaEnv=installCutadapt.condaEnvPath,
            read1=read1,
            read2=read2,
            read1output=cutadaptOutput + "/cutadapt_" + basename(read1),
#            read2output=if defined(read2) then cutadaptOutput + "/cutadapt_" + basename(select_first([read2])) else read2,
            adapter=extractAdaptersRead1.adapterList,
            adapterRead2=extractAdaptersRead2.adapterList
    }

    output {
    File read1afterQC = cutadapt.cutRead1
    File? read2afterQC = cutadapt.cutRead2
    File cutadaptReport = cutadapt.report
    }
}