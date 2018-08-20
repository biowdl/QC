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

import nl.biopet.tools.seqstat.schema.{Aggregation, Data, Readgroup, Root}
import nl.biopet.test.BiopetTest
import nl.biopet.tools.seqstat.GroupStats
import org.testng.annotations.Test

trait QCSuccess extends QCFilesPresent with BiopetTest {

  @Test
  def testSeqStatsReadBefore: Unit = {
    val seqstats: Root = Root.fromFile(seqstatBefore)
    println(seqstats)

    println()
    println(seqstats.samples)
    println(seqstats.samples.keys)
    val seqstat: Data = seqstats
      .samples("sample")
      .libraries("library")
      .readgroups("readgroup")
      .seqstat
    seqstat.r1.aggregation.maxLength shouldBe 100
    seqstat.r1.aggregation.minLength shouldBe 100
    seqstat.r1.aggregation.readsTotal shouldBe 1000

    seqstat.r2.foreach { read =>
      read.aggregation.minLength shouldBe 100
      read.aggregation.maxLength shouldBe 100
      read.aggregation.readsTotal shouldBe 1000
    }
  }

}
