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

import nl.biopet.utils.biowdl.PipelineSuccess
import scala.util.matching.Regex


trait QCSuccess extends QC with PipelineSuccess {
  // When run on clean reads, cutadapt should not be run
  def cutadaptRuns: Boolean = true

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

  // Files from the fastqc task
  mustHaveFastqcDir(s"fastqc/R1/${fastqcName(read1.getName)}")
  addConditionalFile(read2.isDefined, s"fastqc/R2/")
  read2.foreach(file =>
    mustHaveFastqcDir(s"fastqc/R2/${fastqcName(file.getName)}"))

  // Files from the extract adapters task
  addMustHaveFile("extractAdapters")
  addMustHaveFile("extractAdapters/R1/adapter.list")
  addMustHaveFile("extractAdapters/R1/contaminations.list")
  addConditionalFile(read2.isDefined, "extractAdapters/R2/adapter.list")
  addConditionalFile(read2.isDefined, "extractAdapters/R2/contaminations.list")
  addConditionalFile(cutadaptRuns, "cutadapt/report.txt")
}
