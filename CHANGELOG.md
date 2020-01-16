Changelog
==========

<!--

Newest changes should be on top.

This document is user facing. Please word the changes in such a way
that users understand how the changes affect the new version.
-->

version 1.3.0-dev
-----------------
+ Added wdl-aid to linting.
+ Added miniwdl to linting.

version 1.2.0
-----------------
+ Added parameter_meta to QC workflow.
+ Added an overview of all inputs to the docs.
+ Fixed various issues causing miniwdl to be unable to parse the workflow.

version 1.1.0
---------------------------
+ Update tasks so they pass the correct memory requirements to the 
  execution engine. Memory requirements are set on a per-task (not
  per-core) basis.

version 1.0.0
---------------------------
+ Remove default adapter setting for cutadapt. Set defaults in QC inputs.
+ Make sure documentation is up to date.
+ Update cutadapt to version 2.4. This container includes xopen 0.7.3 which
  opens the zipped fastq files through a `pigz` pipe. Also cutadapt 2.4 allows
  setting the compression level for the gzipped output fastq files to 1 instead of 6.
  This makes running cutadapt significantly faster.