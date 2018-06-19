package biowdl.test

import nl.biopet.tools.seqstat.schema.Root

import nl.biopet.test.BiopetTest
import org.testng.annotations.Test

trait QCSuccess extends QCFilesPresent with BiopetTest {

  @Test
  def testSeqStatsRead1: Unit = {
    val seqstats: Root = Root.fromFile(seqstatRead1)
    seqstats.seqstat.foreach(x => {
      val reads = x.r1
      reads.readsTotal shouldBe 1000
      reads.minLength shouldBe 100
      reads.maxLength shouldBe 100
      reads.qualityEncoding shouldBe List("sanger")
    })
  }

}
