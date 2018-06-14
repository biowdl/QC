package biowdl.test

import nl.biopet.utils.biowdl.PipelineSuccess
import nl.biopet.utils.conversions.fileToJson
import play.api.libs.json._
import java.io.File

trait QCSuccess extends QCFilesPresent {

  val seqstatRead1: File = new File(outputDir,"QC/read1/seqstat.json")
  val seqstatRead2: Option[File] = if (read2.isDefined) Some(new File(outputDir, "QC/read2/seqstat.json")) else None
  val seqstatRead1AfterClipping: Option[File] = if (adapterClippingRuns) Some(new File(outputDir,"QCafter/read1/seqstat.json")) else None
  val seqstatRead2AfterClipping: Option[File] = if (adapterClippingRuns && read2.isDefined) Some(new File(outputDir,"QCafter/read1/seqstat.json")) else None
  
  val adaptersRead1: File = new File(outputDir,"QC/read1/extractAdapters/adapter.list")
  val adaptersRead2: Option[File] = if (read2.isDefined) Some(new File(outputDir,"QC/read1/extractAdapters/adapter.list")) else None

  val contaminationsRead1: File = new File(outputDir,"QC/read1/extractAdapters/contaminations.list")
  val contaminationsRead2: Option[File] = if (read2.isDefined) Some(new File(outputDir,"QC/read2/extractAdapters/contaminations.list")) else None

  val fastqcRead1: File = new File (outputDir, s"QC/read1/fastqc/${fastqcName(read1.getName)}/fastqc_data.txt")
  val fastqcRead2: Option[File] = if (read2.isDefined) Some(new File (outputDir, s"QC/read1/fastqc/${fastqcName(read2.map(_.getName).getOrElse(""))}/fastqc_data.txt")) else None
  val fastqcRead1AfterClipping: Option[File] = if (adapterClippingRuns) Some(new File (outputDir, s"QCafter/read1/fastqc/${fastqcName(read1.getName)}/fastqc_data.txt")) else None
  val fastqcRead2AfterClipping: Option[File] = if (read2.isDefined && adapterClippingRuns) Some(new File (outputDir, s"QC/read2/fastqc/${fastqcName(read2.map(_.getName).getOrElse(""))}/fastqc_data.txt")) else None
}

trait QCvalues extends QCSuccess {
  def testSeqStatsRead1 : Unit ={
    val seqstatJson = fileToJson(seqstatRead1)
    seqstatJson

  }

}