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

trait QCSuccess extends QC with PipelineSuccess {
  // When run on clean reads, cutadapt should not be run
  def adapterClippingRuns: Boolean = true

  //TODO: move to utils
  def createOptionalFile(condition: Boolean, path: String*): Option[File] = {
    val p = path.mkString(File.separator)
    addConditionalFile(condition, p)
    if (condition) Some(new File(outputDir, p))
    else None
  }

  //TODO: move to utils
  def createFile(path: String*): File = {
    val p = path.mkString(File.separator)
    addMustHaveFile(p)
    new File(outputDir, p)
  }

  def mustHaveFastqcDir(fastqcBase: String): Unit = {
    addMustHaveFile(fastqcBase)
    addMustHaveFile(fastqcBase + ".zip")
    addMustHaveFile(fastqcBase + ".html")
    addMustHaveFile(fastqcBase, "fastqc_data.txt")
    addMustHaveFile(fastqcBase, "fastqc_report.html")
    addMustHaveFile(fastqcBase, "summary.txt")
    addMustHaveFile(fastqcBase, "Images")
  }

  // Files from the seqstat task
  val seqstatBeforeFile: File = createFile("QC/seqstat.json")
  val seqstatAfterFile: Option[File] = createOptionalFile(adapterClippingRuns, "QCafter/seqstat.json")

  // Files from the extract adapters task
  val adaptersRead1: File =createFile("QC/read1/extractAdapters/adapter.list")
  val adaptersRead2: Option[File] = createOptionalFile(read2.isDefined, "QC/read2/extractAdapters/adapter.list")
  val adaptersRead1After: Option[File] = createOptionalFile(adapterClippingRuns, "QCafter/read1/extractAdapters/adapter.list")
  val adaptersRead2After: Option[File] = createOptionalFile(read2.isDefined && adapterClippingRuns, "QCafter/read2/extractAdapters/adapter.list")

  val contaminationsRead1: File = createFile("QC/read1/extractAdapters/contaminations.list")
  val contaminationsRead2: Option[File] = createOptionalFile(read2.isDefined, "QC/read2/extractAdapters/contaminations.list")
  val contaminationsRead1After: Option[File] = createOptionalFile(adapterClippingRuns, "QC/read1/extractAdapters/contaminations.list")
  val contaminationsRead2After: Option[File] = createOptionalFile(adapterClippingRuns && read2.isDefined, "QC/read2/extractAdapters/contaminations.list")

  // Files from the fastqc task
  val fastqcRead1Dir: File = new File(outputDir, s"QC/read1/fastqc/${QCSuccess.fastqcName(read1.getName)}")
  val fastqcRead2Dir: Option[File] = read2.map(f => new File(outputDir, s"QC/read2/fastqc/${QCSuccess.fastqcName(f.getName)}"))

  val fastqcRead1DataFile: File = new File(fastqcRead1Dir, "fastqc_data.txt")
  val fastqcRead2DataFile: Option[File] = fastqcRead2Dir.map(new File(_, "fastqc_data.txt"))

  val fastqcRead1AfterDir: Option[File] = createOptionalFile(adapterClippingRuns, s"QCafter/read1/fastqc/cutadapt_${QCSuccess.fastqcName(read1.getName)}")

  val fastqcRead2AfterDir: Option[File] = read2.filter(_ => adapterClippingRuns).map(f=> new File(
    outputDir,
    s"QCafter/read2/fastqc/cutadapt_${QCSuccess.fastqcName(f.getName)}"))

  val fastqcRead1AfterDataFile: Option[File] = fastqcRead1AfterDir.map(new File(_, "fastqc_data.txt"))
  val fastqcRead2AfterDataFile: Option[File] = fastqcRead2AfterDir.map(new File(_, "fastqc_data.txt"))

  mustHaveFastqcDir(s"QC/read1/fastqc/${QCSuccess.fastqcName(read1.getName)}")
  addConditionalFile(read2.isDefined, s"QC/read2/fastqc/")
  read2.foreach(file =>
    mustHaveFastqcDir(s"QC/read2/fastqc/${QCSuccess.fastqcName(file.getName)}"))

  if (adapterClippingRuns) {
    mustHaveFastqcDir(
      s"QCafter/read1/fastqc/${"cutadapt_" + QCSuccess.fastqcName(read1.getName)}")
    read2.foreach(
      file =>
        mustHaveFastqcDir(
          s"QCafter/read2/fastqc/${"cutadapt_" + QCSuccess.fastqcName(file.getName)}"))
  }

  // Cutadapt report
  val cutadaptReport: Option[File] = createOptionalFile(adapterClippingRuns, "AdapterClipping/cutadaptReport.txt")

  // Output fastq files
  val fastqRead1FileAfter: Option[File] = createOptionalFile(adapterClippingRuns, "AdapterClipping/cutadapt_" + read1.getName)
  val fastqRead2FileAfter: Option[File] = read2.filter(_ => adapterClippingRuns).map(f => createFile("AdapterClipping/cutadapt_" + f.getName))
}

object QCSuccess {
  val gzip: Regex = "\\.gz$".r
  val extension: Regex = "\\.[^\\.]*$".r
  def fastqcName(name: String): String =
    extension.replaceFirstIn(gzip.replaceFirstIn(name, ""), "_fastqc")
}
