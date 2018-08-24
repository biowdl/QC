/*
 * Copyright (c) 2018 Biowdl
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package biowdl.test

import java.io.File

import nl.biopet.utils.biowdl.PipelineSuccess

import scala.util.matching.Regex

trait QCFilesPresent extends QC with PipelineSuccess {
  // When run on clean reads, cutadapt should not be run
  def adapterClippingRuns: Boolean = true

  val gzip: Regex = "\\.gz$".r
  val extension: Regex = "\\.[^\\.]*$".r
  def fastqcName(name: String): String =
    extension.replaceFirstIn(gzip.replaceFirstIn(name, ""), "_fastqc")

  def mustHaveFastqcDir(fastqcBase: String): Unit = {
    addMustHaveFile(fastqcBase)
    addMustHaveFile(fastqcBase + ".zip")
    addMustHaveFile(fastqcBase + ".html")
    addMustHaveFile(fastqcBase, "fastqc_data.txt")
    addMustHaveFile(fastqcBase, "fastqc_report.html")
    addMustHaveFile(fastqcBase, "summary.txt")
    addMustHaveFile(fastqcBase, "Images")
  }

  val seqstatBefore: File = new File(outputDir, "QC/seqstat.json")
  val seqstatAfterClipping: Option[File] =
    if (adapterClippingRuns)
      Some(new File(outputDir, "QCafter/seqstat.json"))
    else None

  val adaptersRead1: File =
    new File(outputDir, "QC/read1/extractAdapters/adapter.list")
  val adaptersRead2: Option[File] =
    if (read2.isDefined)
      Some(new File(outputDir, "QC/read1/extractAdapters/adapter.list"))
    else None

  val contaminationsRead1: File =
    new File(outputDir, "QC/read1/extractAdapters/contaminations.list")
  val contaminationsRead2: Option[File] =
    if (read2.isDefined)
      Some(new File(outputDir, "QC/read2/extractAdapters/contaminations.list"))
    else None

  val fastqcRead1: File = new File(
    outputDir,
    s"QC/read1/fastqc/${fastqcName(read1.getName)}/fastqc_data.txt")
  val fastqcRead2: Option[File] =
    if (read2.isDefined)
      Some(
        new File(
          outputDir,
          s"QC/read2/fastqc/${fastqcName(read2.map(_.getName).getOrElse(""))}/fastqc_data.txt"))
    else None
  val fastqcRead1AfterClipping: Option[File] =
    if (adapterClippingRuns)
      Some(
        new File(
          outputDir,
          s"QCafter/read1/fastqc/cutadapt_${fastqcName(read1.getName)}/fastqc_data.txt"))
    else None
  val fastqcRead2AfterClipping: Option[File] =
    if (read2.isDefined && adapterClippingRuns)
      Some(
        new File(
          outputDir,
          s"QCafter/read2/fastqc/cutadapt_${fastqcName(read2.map(_.getName).getOrElse(""))}/fastqc_data.txt"))
    else None

  // Files from the fastqc task
  mustHaveFastqcDir(s"QC/read1/fastqc/${fastqcName(read1.getName)}")
  addConditionalFile(read2.isDefined, s"QC/read2/fastqc/")
  read2.foreach(file =>
    mustHaveFastqcDir(s"QC/read2/fastqc/${fastqcName(file.getName)}"))

  addMustHaveFile("QC/seqstat.json")

  // Files from the extract adapters task
  addMustHaveFile("QC/read1/extractAdapters")
  addMustHaveFile("QC/read1/extractAdapters/adapter.list")
  addMustHaveFile("QC/read1/extractAdapters/contaminations.list")
  addConditionalFile(read2.isDefined, "QC/read2/extractAdapters/adapter.list")
  addConditionalFile(read2.isDefined,
                     "QC/read2/extractAdapters/contaminations.list")

  addConditionalFile(adapterClippingRuns, "AdapterClipping/cutadaptReport.txt")
  addConditionalFile(adapterClippingRuns,
                     "AdapterClipping/cutadapt_" + read1.getName)
  addConditionalFile(
    adapterClippingRuns && read2.isDefined,
    "AdapterClipping/cutadapt_" + read2.map(_.getName).getOrElse("read2"))

  addConditionalFile(adapterClippingRuns, "QCafter/seqstat.json")
  if (adapterClippingRuns) {
    addMustNotHaveFile("QCafter/read1/extractAdapters/adapter.list")
    addMustNotHaveFile("QCafter/read1/extractAdapters/contaminations.list")
  }
  if (adapterClippingRuns && read2.isDefined) {
    addMustNotHaveFile("QCafter/read2/extractAdapters/adapter.list")
    addMustNotHaveFile("QCafter/read2/extractAdapters/contaminations.list")
  }
  if (adapterClippingRuns) {
    mustHaveFastqcDir(
      s"QCafter/read1/fastqc/${"cutadapt_" + fastqcName(read1.getName)}")
    read2.foreach(
      file =>
        mustHaveFastqcDir(
          s"QCafter/read2/fastqc/${"cutadapt_" + fastqcName(file.getName)}"))
  }
}
