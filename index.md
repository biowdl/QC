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
- ValidateFastqFiles.wdl: Validates FASTQ files.

## Usage

### `AdapterClipping.wdl`
`AdapterClipping.wdl` can be run using
[Cromwell](http://cromwell.readthedocs.io/en/stable/):
```
java -jar cromwell-<version>.jar run -i inputs.json AdapterClipping.wdl
```

The inputs JSON can be generated using WOMtools as described in the [WOMtools
documentation](http://cromwell.readthedocs.io/en/stable/WOMtool/).

The primary inputs are described below, additional inputs (such as precommands)
are available. Please use the above mentioned WOMtools command to see all
available inputs.

| field | type | |
|-|-|-|
| read1 | `File` | Input R1 FASTQ file. |
| read2 | `File?` | Input R2 FASTQ file. |
| outputDir | `String` | The output directory. |
| adapterListRead1 | `Array[String]+?` | A list of adapter sequences to be cut from R1. |
| adapterListRead2 | `Array[String]+?` | A list of adapter sequences to be cut from R2. |

>All inputs have to be preceded by `AdapterClipping.`.
Type is indicated according to the WDL data types: `File` should be indicators
of file location (a string in JSON). Types ending in `?` indicate the input is
optional, types ending in `+` indicate they require at least one element.

### `QC.wdl`
`QC.wdl` can be run using
[Cromwell](http://cromwell.readthedocs.io/en/stable/):
```
java -jar cromwell-<version>.jar run -i inputs.json QC.wdl
```

The inputs JSON can be generated using WOMtools as described in the [WOMtools
documentation](http://cromwell.readthedocs.io/en/stable/WOMtool/).

The primary inputs are described below, additional inputs (such as precommands)
are available. Please use the above mentioned WOMtools command to see all
available inputs.

| field | type | |
|-|-|-|
| read1 | `File` | Input R1 FASTQ file. |
| read2 | `File?` | Input R2 FASTQ file. |
| outputDir | `String` | The output directory. |

>All inputs have to be preceded by `QC.`.
Type is indicated according to the WDL data types: `File` should be indicators
of file location (a string in JSON). Types ending in `?` indicate the input is
optional, types ending in `+` indicate they require at least one element.

### `QualityReport.wdl`
`QualityReport.wdl` can be run using
[Cromwell](http://cromwell.readthedocs.io/en/stable/):
```
java -jar cromwell-<version>.jar run -i inputs.json QualityReport.wdl
```

The inputs JSON can be generated using WOMtools as described in the [WOMtools
documentation](http://cromwell.readthedocs.io/en/stable/WOMtool/).

The primary inputs are described below, additional inputs (such as precommands)
are available. Please use the above mentioned WOMtools command to see all
available inputs.

| field | type | default | |
|-|-|-|-|
| outputDir | `String` | | The output directory. |
| extractAdapters | `Boolean` | `false` | Whether or not to extract a list of detected adapters from the FastQC output. |
| read | `File` | | The input FASTQ file. |

>All inputs have to be preceded by `QualityReport.`.
Type is indicated according to the WDL data types: `File` should be indicators
of file location (a string in JSON). Types ending in `?` indicate the input is
optional, types ending in `+` indicate they require at least one element.

### `ValidateFastqFiles.wdl`
`ValidateFastqFiles.wdl` can be run using
[Cromwell](http://cromwell.readthedocs.io/en/stable/):
```
java -jar cromwell-<version>.jar run -i inputs.json ValidateFastqFiles.wdl
```

The inputs JSON can be generated using WOMtools as described in the [WOMtools
documentation](http://cromwell.readthedocs.io/en/stable/WOMtool/).

The primary inputs are described below, additional inputs (such as precommands)
are available. Please use the above mentioned WOMtools command to see all
available inputs.

| field | type | |
|-|-|-|
| read1 | `File` | The first-end FASTQ file. |
| read2 | `File?` | The second-end FASTQ file. |

>All inputs have to be preceded by `ValidateFastqFiles.`.
Type is indicated according to the WDL data types: `File` should be indicators
of file location (a string in JSON). Types ending in `?` indicate the input is
optional, types ending in `+` indicate they require at least one element.

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

### `ValidateFastqFiles.wdl`
This workflow doesn't produce any output, but fails if validation fails.

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
