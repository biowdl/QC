---
layout: default
title: Home
version: develop
latest: true
---

This repository contains a collection of [BioWDL](https://github.com/biowdl)
workflows which can be used for quality control preprocessing and reporting of
sequencing data. The following workflows are available:
- QC.wdl: Cuts reads using cutadapt on the basis of the quality reports produced by `QualityReport.wdl`.
- QualityReport.wdl: Uses fastqc of tools to produce quality reports.

These workflows are part of [BioWDL](https://biowdl.github.io/)
developed by [the SASC team](http://sasc.lumc.nl/).

## Usage

`QC.wdl` can be run using
[Cromwell](http://cromwell.readthedocs.io/en/stable/):
```
java -jar cromwell-<version>.jar run -i inputs.json QC.wdl
```

### Input

Inputs are provided through a JSON file. The minimally required inputs are
described below, but additional inputs are available.
A template containing all possible inputs can be generated using
Womtool as described in the
[WOMtool documentation](http://cromwell.readthedocs.io/en/stable/WOMtool/).
See [this page](/inputs.html) for some additional general notes and information
about pipeline inputs.

```JSON
{
  "QC.read1": "Path to read1",
  "QC.read2": "Path to read2",
  "QC.outputDir":"Where the results should be output to",
  "QC.alwaysRunAdapterClipping": "Boolean (Optional) Whether adapter clipping should always run. Use this if you want to add custom paramaters for read preprocessing. Defaults to 'false'",
}
```

#### Example

An example of an inputs.json might look like this:
```JSON
{
  "QC.read1":"/home/user/samples/sample_1/lib_1/rg_1/R1.fq.gz",
  "QC.read2":"/home/user/samples/sample_1/lib_1/rg_1/R2.fq.gz",
  "QC.outputDir":"/home/user/analysis/QCed_reads/",
}
```

### Dependency requirements and tool versions
Included in the repository is an `environment.yml` file. This file includes
all the tool version on which the workflow was tested. You can use conda and
this file to create an environment with all the correct tools.

### Output

A new set of FASTQ files from which detected adapters have been clipped and a
set of quality reports.

## Contact
<p>
  <!-- Obscure e-mail address for spammers -->
For any question related to these workflows, please use the
<a href='https://github.com/biowdl/QC/issues'>github issue tracker</a>
or contact
 <a href='http://sasc.lumc.nl/'>the SASC team</a> directly at: <a href='&#109;&#97;&#105;&#108;&#116;&#111;&#58;&#115;&#97;&#115;&#99;&#64;&#108;&#117;&#109;&#99;&#46;&#110;&#108;'>
&#115;&#97;&#115;&#99;&#64;&#108;&#117;&#109;&#99;&#46;&#110;&#108;</a>.
</p>
