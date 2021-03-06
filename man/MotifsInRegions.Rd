% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/FindMotifsInRegions.R
\docType{methods}
\name{MotifsInRegions}
\alias{MotifsInRegions}
\alias{enrichFindMotifsInRegions,Step-method}
\alias{enrichFindMotifsInRegions}
\alias{findMotifsInRegions}
\alias{motifsInRegions}
\title{Find motifs in all input sequence regions}
\usage{
enrichFindMotifsInRegions(prevStep, inputRegionBed = NULL,
  outputRegionMotifBed = NULL, motifRc = c("integrate", "jaspar",
  "pwmfile"), inputPwmFile = getRefFiles("motifpwm"),
  genome = getGenome(), ...)

\S4method{enrichFindMotifsInRegions}{Step}(prevStep,
  inputRegionBed = NULL, outputRegionMotifBed = NULL,
  motifRc = c("integrate", "jaspar", "pwmfile"),
  inputPwmFile = getRefFiles("motifpwm"), genome = getGenome(), ...)

findMotifsInRegions(inputRegionBed, outputRegionMotifBed = NULL,
  motifRc = c("integrate", "jaspar", "pwmfile"),
  inputPwmFile = getRefFiles("motifpwm"), genome = getGenome(), ...)
}
\arguments{
\item{prevStep}{\code{\link{Step-class}} object scalar.
It needs to be the return value of upstream process from \code{\link{genBackground}} or \code{\link{enrichGenBackground}}
when it is not used in a pipeline.  If it is used in a pipeline or \code{\%>\%} is applied on this function, any steps in this package is acceptable.}

\item{inputRegionBed}{\code{Character} scalar.
BED file for regions including foreground and background sequences.}

\item{outputRegionMotifBed}{\code{Character} scalar.
BED file for regions with motif candidates.
Default: NULL (generated base on inputForegroundBed)}

\item{motifRc}{\code{Character} scalar.
Motif Resources can be one of "integrate"
(integrated by us and can be download from internet automatically
if call the function \code{setGenome("hg19")}),
"jaspar" package JASPAR2018,
or "pwmfile" (User defined PWM file. inputPwmFile is required).}

\item{inputPwmFile}{\code{Character} scalar.
when "pwmfile" is set for motifRc, use this argument to provide PWM file directory.}

\item{genome}{\code{Character} scalar.
Bioconductor supported genome, such as "hg19", "mm10", etc.
Default: NULL (e.g. after \code{library (enrichTF)}, you can call function \code{setGenome("hg19")})}

\item{...}{Additional arguments, currently unused.}
}
\value{
An invisible \code{\link{EnrichStep-class}} object (\code{\link{Step-class}} based) scalar for downstream analysis.
}
\description{
Scan for motif occurrences using the prepared PWMs and obtain the promising candidate motifs in these regions.
}
\details{
Scan for motif occurrences using the prepared PWMs and
obtain the promising candidate motifs in these regions.
}
\examples{
setGenome("testgenome") #Use "hg19","hg38",etc. for your application
foregroundBedPath <- system.file(package = "enrichTF", "extdata","testregion.bed")
gen <- genBackground(inputForegroundBed = foregroundBedPath)
# findMotif <- enrichFindMotifsInRegions(gen,motifRc="integrate")
}
\seealso{
\code{\link{genBackground}}
\code{\link{findMotifsInRegions}}
\code{\link{tfsEnrichInRegions}}
}
\author{
Zheng Wei
}
