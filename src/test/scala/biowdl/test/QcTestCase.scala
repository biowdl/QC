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

import nl.biopet.tools.seqstat.GroupStats
import nl.biopet.tools.seqstat.schema.{Data => SeqstatData, Root}
import nl.biopet.tools.extractadaptersfastqc.ExtractAdaptersFastqc.{
  AdapterSequence,
  foundAdapters,
  foundOverrepresented,
  getFastqcSeqs,
  qcModules
}
import org.testng.annotations.{DataProvider, Test}
import java.io.File

import scala.io.Source
import util.Properties.lineSeparator

trait QcTestCase extends QCSuccess {

  // Defining values for the test set.
  val read1MaxLength = 100
  val read2MaxLength = 100
  val read1MinLength = 100
  val read2MinLength = 100
  val read1TotalReads = 1000
  val read1TotalBases = 100000
  val read2TotalReads = 1000
  val read2TotalBases = 100000
  val encodings = List("Illumina 1.8+")

  def seqstatData(file: File): SeqstatData = {
    Root
      .fromFile(file)
      .samples(sample)
      .libraries(library)
      .readgroups(readgroup)
      .seqstat
  }

  def seqstatBefore: SeqstatData = seqstatData(seqstatBeforeFile)
  def seqstatAfter: Option[SeqstatData] = seqstatAfterFile.map(seqstatData)

  @Test
  def testSeqStatsReadBefore(): Unit = {
    val seqstat: SeqstatData = seqstatBefore
    seqstat.r1.aggregation.maxLength shouldBe read1MaxLength
    seqstat.r1.aggregation.minLength shouldBe read1MinLength
    seqstat.r1.aggregation.readsTotal shouldBe read1TotalReads
    seqstat.r1.aggregation.qualityEncoding shouldBe encodings

    seqstat.r2.foreach { read =>
      read.aggregation.minLength shouldBe read2MinLength
      read.aggregation.maxLength shouldBe read2MaxLength
      read.aggregation.readsTotal shouldBe read2TotalReads
      read.aggregation.qualityEncoding shouldBe encodings
    }

    val groupStats = seqstat.asGroupStats
    groupStats.r1qual.totalBases shouldBe read1TotalBases
    groupStats.r2qual.foreach(_.totalBases shouldBe read2TotalBases)
    groupStats.isPaired shouldBe this.read2.isDefined
  }

  @Test
  def testSeqStatsReadAfter(): Unit = {
    val seqstats: Option[Root] = seqstatAfterFile.map(Root.fromFile)
    seqstats.isDefined shouldBe adapterClippingRuns
    seqstats.foreach { stats =>
      val seqstat: SeqstatData = stats
        .samples(sample)
        .libraries(library)
        .readgroups(readgroup)
        .seqstat
      seqstat.r1.aggregation.readsTotal shouldNot be(read1TotalReads) // Some reads should be dropped after clipping
      seqstat.r1.aggregation.maxLength shouldBe read1MaxLength // Assuming some reads are not cut
      seqstat.r1.aggregation.minLength shouldNot be(read1MinLength) // some reads should be cut
      seqstat.r1.aggregation.basesTotal shouldNot be(read1TotalBases) // Definitely some bases will have been gone.
      seqstat.r2.foreach { read =>
        read.aggregation.readsTotal shouldNot be(read2TotalReads)
        read.aggregation.maxLength shouldBe read2MaxLength
        read.aggregation.minLength shouldNot be(read2MinLength)
        read.aggregation.basesTotal shouldNot be(read2TotalBases)
      }
      val groupStats: GroupStats = seqstat.asGroupStats
      groupStats.r1qual.totalBases shouldNot be(read1TotalBases)
      groupStats.r2qual.foreach(_.totalBases shouldNot be(read1TotalBases))
      groupStats.isPaired shouldBe this.read2.isDefined
    }
  }

  @Test
  def testAdaptersContaminationsFiles(): Unit = {
    val adaptersFromRead1: Set[String] =
      Source.fromFile(adaptersRead1).mkString.split(lineSeparator).toSet
    val adaptersFromRead2: Option[Set[String]] =
      adaptersRead2.map(Source.fromFile(_).mkString.split(lineSeparator).toSet)
    val contaminationsFromRead1: Set[String] =
      Source.fromFile(contaminationsRead1).mkString.split(lineSeparator).toSet
    val contaminationsFromRead2: Option[Set[String]] = contaminationsRead2.map(
      Source.fromFile(_).mkString.split(lineSeparator).toSet)
    adaptersFromRead1 shouldBe Set("AGATCGGAAGAG")
    adaptersFromRead2.foreach(_ shouldBe Set("AGATCGGAAGAG"))
    contaminationsFromRead1 shouldBe Set(
      "GATCGGAAGAGCACACGTCTGAACTCCAGTCACGTCCGCATCTCGTATGCCGTCTTCTGCTTG", // TruSeq Adapter, Index 18
      "GATCGGAAGAGCACACGTCTGAACTCCAGTCACATCACGATCTCGTATGCCGTCTTCTGCTTG" // TruSeq Adapter, Index 1
    )
    contaminationsFromRead2.foreach(_ shouldBe Set())
  }

  def fastQCtoAdapters(fastqcFile: File): Set[AdapterSequence] = {
    val knownAdapters = getFastqcSeqs(resourceFile("/adapter_list.txt"))
    foundAdapters(qcModules(fastqcFile), 0.0001, knownAdapters)
  }

  def fastQCtoContaminations(fastqcFile: File): Set[AdapterSequence] = {
    val knownContaminations = getFastqcSeqs(
      resourceFile("/contaminant_list.txt"))
    foundOverrepresented(qcModules(fastqcFile), knownContaminations)
  }

  @DataProvider(name = "fastQCFiles")
  def provider: Array[Array[Any]] = {
    val adaptersInTest: Set[AdapterSequence] = Set(
      AdapterSequence("Illumina Universal Adapter", "AGATCGGAAGAG")
    )
    Array(
      Array(Some(fastqcRead1DataFile), adaptersInTest),
      Array(fastqcRead2DataFile, adaptersInTest),
      Array(fastqcRead1AfterDataFile, Set()),
      Array(fastqcRead2AfterDataFile, Set())
    )
  }

  @Test(dataProvider = "fastQCFiles")
  def testAdapters(fastqcFile: Option[File],
                   adapterSet: Set[AdapterSequence]): Unit = {
    fastqcFile.foreach { file =>
      fastQCtoAdapters(file) shouldBe adapterSet
    }
  }

  @Test
  def testContaminations(): Unit = {
    val contaminationsInTest: Set[AdapterSequence] = Set(
      AdapterSequence(
        "TruSeq Adapter, Index 18",
        "GATCGGAAGAGCACACGTCTGAACTCCAGTCACGTCCGCATCTCGTATGCCGTCTTCTGCTTG"),
      AdapterSequence(
        "TruSeq Adapter, Index 1",
        "GATCGGAAGAGCACACGTCTGAACTCCAGTCACATCACGATCTCGTATGCCGTCTTCTGCTTG")
    )
    fastQCtoContaminations(fastqcRead1DataFile) shouldBe contaminationsInTest
    fastqcRead2DataFile.map(fastQCtoContaminations).foreach(_ shouldBe Set())
    // This tests whether all found contaminations where removed
    fastqcRead1AfterDataFile.foreach { fastqcFile =>
      val contaminationsAfterClipping = fastQCtoContaminations(fastqcFile)
      contaminationsAfterClipping.foreach(
        contaminationsInTest shouldNot contain(_))
    }
  }

}
