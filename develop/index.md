---
layout: default
title: Home
version: develop
latest: true
---

This repository contains a collection of [BioWDL](https://github.com/biowdl)
workflows which can be used for quality control preprocessing and reporting of
sequencing data. The following workflows are available:
- AdapterClipping.wdl: Uses cutadapt to perform adapter clipping.
- QC.wdl: Combines the other workflows in this repository.
- QualityReport.wdl: Uses a number of tools to produce quality reports.

## Usage

### `QC.wdl`
`QC.wdl` can be run using
[Cromwell](http://cromwell.readthedocs.io/en/stable/):
```
java -jar cromwell-<version>.jar run -i inputs.json QC.wdl
```
Inputs are provided through a JSON file. The minimally required inputs are
described below, but additional inputs are available.
A template containing all possible inputs can be generated using
Womtool as described in the
[WOMtool documentation](http://cromwell.readthedocs.io/en/stable/WOMtool/).
See [this page](/inputs.html) for some additional general notes and information
about pipeline inputs.

```JSON
{
  "QC.reads": {
    "R1":"Path to read1",
    "R1_md5": "(Optional) path to read1.md5",
    "R2":"Path to read2",
    "R2_md5": "(Optional) path to read1.md5"
  },
  "QC.outputDir":"Where the results should be output to",
  "QC.alwaysRunAdapterClipping": "Boolean (Optional) Whether adapter clipping should always run. Use this if you want to add custom paramaters for read preprocessing. Defaults to 'false'",
  "QC.sample": "Sample name that will be used in the Seqstat output",
  "QC.library": "Library name that will be used in the Seqstat output",
  "QC.readgroup": "Readgroup that can be used in the Seqstat output"
}
```

### Example

An example of an inputs.json might look like this:
```JSON
{
  "QC.reads": {
    "R1":"/home/user/samples/sample_1/lib_1/rg_1/R1.fq.gz",
    "R2":"/home/user/samples/sample_1/lib_1/rg_1/R2.fq.gz"
  },
  "QC.outputDir":"/home/user/analysis/QCed_reads/",
  "QC.sample": "sample_1",
  "QC.library": "lib_1",
  "QC.readgroup": "rg_1"
}
```

## Tool versions
Included in the repository is an `environment.yml` file. This file includes
all the tool version on which the workflow was tested. You can use conda and
this file to create an environment with all the correct tools.

## Output
### `AdapterClipping.wdl`
A new set of FASTQ files from which the given adapters have been clipped.

### `QC.wdl`
A new set of FASTQ files from which detected adapters have been clipped and a
set of quality reports.

### `QualityReport.wdl`
A number of quality reports.

## About
These workflows are part of [BioWDL](https://biowdl.github.io/)
developed by [the SASC team](http://sasc.lumc.nl/).

## Contact
<p>
  <!-- Obscure e-mail address for spammers -->
For any question related to these workflows, please use the
<a href='https://github.com/biowdl/QC/issues'>github issue tracker</a>
or contact
 <a href='http://sasc.lumc.nl/'>the SASC team</a> directly at: <a href='&#109;&#97;&#105;&#108;&#116;&#111;&#58;&#115;&#97;&#115;&#99;&#64;&#108;&#117;&#109;&#99;&#46;&#110;&#108;'>
&#115;&#97;&#115;&#99;&#64;&#108;&#117;&#109;&#99;&#46;&#110;&#108;</a>.
</p>
