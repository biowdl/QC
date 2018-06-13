# Copyright 2018 Sequencing Analysis Support Core - Leiden University Medical Center

import "tasks/cutadapt.wdl" as cutadapt

workflow AdapterClipping {
    File read1
    File? read2
    String? outputDir
    Array[String]+? adapterListRead1
    Array[String]+? adapterListRead2


    if (defined(read2)) {
        String read2outputPath = outputDir + "/cutadapt_" + basename(select_first([read2]))
    }

    call cutadapt.cutadapt {
        input:
            read1 = read1,
            read2 = read2,
            read1output = outputDir + "/cutadapt_" + basename(read1),
            read2output = read2outputPath,
            adapter = adapterListRead1,
            adapterRead2 = adapterListRead2,
            reportPath = outputDir + "/report.txt"
    }
    output {
        file read1afterTrim = cutadapt.cutread1
        file read2afterTrim = cutadapt.cutRead2
        file cutadaptReport = cutadapt.report
    }
}
