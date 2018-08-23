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

import nl.biopet.test.BiopetTest
import nl.biopet.tools.seqstat.GroupStats
import nl.biopet.tools.seqstat.schema.{Data, Root}
import org.testng.annotations.Test

import scala.io.Source
import util.Properties.lineSeparator

trait QCSuccess extends QCFilesPresent with BiopetTest {

  @Test
  def testSeqStatsReadBefore(): Unit = {
    val seqstats: Root = Root.fromFile(seqstatBefore)
    val seqstat: Data = seqstats
      .samples(sample)
      .libraries(library)
      .readgroups(readgroup)
      .seqstat
    seqstat.r1.aggregation.maxLength shouldBe 100
    seqstat.r1.aggregation.minLength shouldBe 100
    seqstat.r1.aggregation.readsTotal shouldBe 1000
    seqstat.r1.aggregation.qualityEncoding shouldBe List("Illumina 1.8+")

    seqstat.r2.foreach { read =>
      read.aggregation.minLength shouldBe 100
      read.aggregation.maxLength shouldBe 100
      read.aggregation.readsTotal shouldBe 1000
      read.aggregation.qualityEncoding shouldBe List("Illumina 1.8+")
    }

    val groupStats = seqstat.asGroupStats
    groupStats.r1qual.totalBases shouldBe 100000
    groupStats.r2qual.foreach(_.totalBases shouldBe 100000)
    groupStats.isPaired shouldBe this.read2.isDefined
  }

  @Test
  def testSeqStatsReadAfter(): Unit = {
    val seqstats: Option[Root] = seqstatAfterClipping.map(Root.fromFile)
    seqstats.isDefined shouldBe adapterClippingRuns
    seqstats.foreach { stats =>
      val seqstat: Data = stats
        .samples(sample)
        .libraries(library)
        .readgroups(readgroup)
        .seqstat
      seqstat.r1.aggregation.readsTotal shouldNot be(1000)
      seqstat.r1.aggregation.maxLength shouldBe 100
      seqstat.r1.aggregation.minLength shouldNot be(100)
      seqstat.r1.aggregation.basesTotal shouldNot be(100000)
      seqstat.r2.foreach { read =>
        read.aggregation.readsTotal shouldNot be(1000)
        read.aggregation.maxLength shouldBe 100
        read.aggregation.minLength shouldNot be(100)
        read.aggregation.basesTotal shouldNot be(100000)
      }
      val groupStats: GroupStats = seqstat.asGroupStats
      groupStats.r1qual.totalBases shouldNot be(100000)
      groupStats.r2qual.foreach(_.totalBases shouldNot be(100000))
      groupStats.isPaired shouldBe this.read2.isDefined
    }
  }

  @Test
  def testAdaptersContaminations(): Unit = {
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
}
