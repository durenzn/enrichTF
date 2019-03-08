setClass(Class = "TFsEnrichInRegions",
         contains = "EnrichStep"
)

setMethod(
    f = "init",
    signature = "TFsEnrichInRegions",
    definition = function(.Object,prevSteps = list(),...){
        allparam <- list(...)
        print(allparam)
        inputRegionBed <- allparam[["inputRegionBed"]]
        inputForegroundGeneBed <- allparam[["inputForegroundGeneBed"]]
        inputBackgroundGendBed <- allparam[["inputBackgroundGendBed"]]
        inputRegionMotifBed <- allparam[["inputRegionMotifBed"]]
        outputTFsEnrichTxt <- allparam[["outputTFsEnrichTxt"]]
        inputMotifWeights <- allparam[["inputMotifWeights"]]
        inputTFgeneRelMtx <- allparam[["inputTFgeneRelMtx"]]
        inputMotifTFTable <- allparam[["inputMotifTFTable"]]
        if(length(prevSteps)>0){
            GenBackgroundStep <- prevSteps[[1]]
            FindMotifsInRegionsStep  <- prevSteps[[2]]
            RegionConnectTargetGeneStep  <- prevSteps[[3]]
            .Object@inputList[["inputRegionBed"]] <- getParam(GenBackgroundStep,"outputRegionBed")
            .Object@inputList[["inputRegionMotifBed"]] <- getParam(FindMotifsInRegionsStep,"outputRegionMotifBed")
            .Object@inputList[["inputForegroundGeneBed"]] <- getParam(RegionConnectTargetGeneStep,"outputForegroundBed")
            .Object@inputList[["inputBackgroundGendBed"]] <- getParam(RegionConnectTargetGeneStep,"outputBackgroundBed")
        }


        if(is.null(outputTFsEnrichTxt)){
            .Object@outputList[["outputTFsEnrichTxt"]] <- getAutoPath(.Object,originPath = .Object@inputList[["inputRegionBed"]],regexProcName = "allregion.bed",suffix = "PECA_TF_enrich.txt")
        }else{
            .Object@outputList[["outputTFsEnrichTxt"]] <- outputTFsEnrichTxt
        }

        if(!is.null(inputRegionBed)){
            .Object@inputList[["inputRegionBed"]] <- inputRegionBed
        }
        if(!is.null(inputRegionMotifBed)){
            .Object@inputList[["inputRegionMotifBed"]] <- inputRegionMotifBed
        }
        if(!is.null(inputForegroundGeneBed)){
            .Object@inputList[["inputForegroundGeneBed"]] <- inputForegroundGeneBed
        }
        if(!is.null(inputBackgroundGendBed)){
            .Object@inputList[["inputBackgroundGendBed"]] <- inputBackgroundGendBed
        }

        if(is.null(inputMotifWeights)){
            .Object@inputList[["inputMotifWeights"]] <- getRefFiles("MotifWeights")
        }else{
            .Object@inputList[["inputMotifWeights"]] <- inputMotifWeights
        }
        if(is.null(inputTFgeneRelMtx)){
            .Object@inputList[["inputTFgeneRelMtx"]] <- getRefFiles("TFgeneRelMtx")
        }else{
            .Object@inputList[["inputTFgeneRelMtx"]] <- inputTFgeneRelMtx
        }
        if(is.null(inputMotifTFTable)){
            .Object@inputList[["inputMotifTFTable"]] <- getRefFiles("MotifTFTable")
        }else{
            .Object@inputList[["inputMotifTFTable"]] <- inputMotifTFTable
        }
        .Object
    }
)


setMethod(
    f = "processing",
    signature = "TFsEnrichInRegions",
    definition = function(.Object,...){

        inputRegionBed <- getParam(.Object,"inputRegionBed")
        inputForegroundGeneBed <- getParam(.Object,"inputForegroundGeneBed")
        inputBackgroundGendBed <- getParam(.Object,"inputBackgroundGendBed")
        inputRegionMotifBed <- getParam(.Object,"inputRegionMotifBed")
        outputTFsEnrichTxt <- getParam(.Object,"outputTFsEnrichTxt")
        inputMotifWeights <- getParam(.Object,"inputMotifWeights")
        inputTFgeneRelMtx <- getParam(.Object,"inputTFgeneRelMtx")
        inputMotifTFTable <- getParam(.Object,"inputMotifTFTable")

        print(.Object@inputList)
        print(.Object@outputList)
        print(.Object@paramList)

        if(endsWith(inputMotifWeights,".RData")){
            load(inputMotifWeights)
            inputMotifWeights <- motifWeights
        }else{
            inputMotifWeights<- read.table(inputMotifWeights,sep = '\t', header = FALSE)
            colnames(inputMotifWeights) <- c("motifName","motifWeight")
        }

        if(endsWith(inputTFgeneRelMtx,".RData")){
            load(inputTFgeneRelMtx)
            inputTFgeneRelMtx <- tfGeneRelMtx
        }else{
            inputTFgeneRelMtx<- read.table(inputTFgeneRelMtx,sep = '\t', header = TRUE)
        }

        if(endsWith(inputMotifTFTable,".RData")){
            load(inputMotifTFTable)
            inputMotifTFTable <- motifTFTable
        }else{
            inputMotifTFTable<- read.table(inputMotifTFTable,sep = '\t', header = FALSE)
            colnames(inputMotifTFTable) <- c("motifName", "tfName")
        }



        geneName <- colnames(inputTFgeneRelMtx)
        genes <- data.frame(geneName = geneName, name = 1:length(geneName))
        tfName <- rownames(inputTFgeneRelMtx)
        tfs <- data.frame(tfName = tfName, name = 1:length(tfName))
        inputMotifWeights <- cbind(inputMotifWeights,1:nrow(inputMotifWeights))
        motifName <- as.character(inputMotifWeights[,1])
        motifWeight <- as.numeric(inputMotifWeights[,2])

        regionBed <- import.bed(con = inputRegionBed)
        foregroundGeneBed  <- read.table(inputForegroundGeneBed,sep = "\t")
        colnames(foregroundGeneBed) <- c("seqnames","start","end","name","score",
                                         "geneName","blockCount")
        backgroundGendBed <- read.table(inputBackgroundGendBed,sep = "\t")
        colnames(backgroundGendBed)  <- c("seqnames","start","end","name","score",
                                          "geneName","blockCount")
        regionMotifBed <- read.table(inputRegionMotifBed,sep = "\t")
        colnames(regionMotifBed) <- c("seqnames","start","end","name","score","motifName")

        motifWeight1 <- log(1/(motifWeight + 0.1) + 1)
        motifidx <- match(regionMotifBed$motifName,motifName)
        inputMotifWeights <- cbind(inputMotifWeights,motifWeight1)
        regionMotifWeight <- inputMotifWeights[motifidx[!is.na(motifidx)],]

#        foregroundRegionGene <- merge(x=foregroundGeneBed,y=genes, by.x = "geneName" ,  by.y = "genName")
#        backgroundRegionGene <- merge(x=backgroundGendBed,y=genes, by.x = "geneName" ,  by.y = "genName")

#        rbind(foregroundRegionGene,backgroundRegionGene)

        pValue <- matrix(1,nrow = length(tfName),ncol = 4)

        for(i in 1:length(tfName)){



            pValue[i,2] <- t.test(x = inputTFgeneRelMtx[i,foregroundGeneBed$geneName],
                                 y = inputTFgeneRelMtx[i,backgroundGendBed$geneName],
                                 alternative = "greater")$p.value

            motifsOfTF <- inputMotifTFTable[inputMotifTFTable$tfName == tfName[i],1]

            if(length(motifsOfTF)==0){
                next
            }
            print(i)


            print(motifsOfTF)

            pvalueOfFisher<- sapply(1:length(motifsOfTF), function(motifsOfTFi) {
                print(motifsOfTFi)



                motif <- motifsOfTF[motifsOfTFi]
                print(motif)
                regionsName <- regionMotifBed[regionMotifBed$motifName == motif, c("name")]
                foregroundGeneFalledInMotifReiong<-match(foregroundGeneBed$name , regionsName)
                backgroundGeneFalledInMotifReiong<-match(BackgroundGeneBed$name , regionsName)


                fisherMtx <- matrix(0,nrow = 2,ncol = 2)
                fisherMtx[1,1] <- sum(!is.na(foregroundGeneFalledInMotifReiong))
                fisherMtx[1,2] <- sum(is.na(foregroundGeneFalledInMotifReiong))
                fisherMtx[2,1] <- sum(!is.na(foregroundGeneFalledInMotifReiong))
                fisherMtx[2,2] <- sum(is.na(foregroundGeneFalledInMotifReiong))

                fisher.test(fisherMtx)$p.value
            })
            pValue[i,1] <- min(pvalueOfFisher)
            motif <- motifsOfTF[which.min(pvalueOfFisher)]
            regionsName <- regionMotifBed[regionMotifBed$motifName == motif, c("name")]
            foregroundGeneFalledInMotifReiong<-match(foregroundGeneBed$name , regionsName)
            backgroundGeneFalledInMotifReiong<-match(BackgroundGeneBed$name , regionsName)

            pvalueOfFisher1 <- sapply(-9:9, function(cut_off){
                cut_off <- cut_off /10
                genesName <- geneName[inputTFgeneRelMtx[i,] > cut_off]
                foregroundGeneAboveCutOff<-match(foregroundGeneBed$geneName , regionsName)
                backgroundGeneAboveCutOff<-match(BackgroundGeneBed$geneName , regionsName)

                forePos <- is.na(foregroundGeneFalledInMotifReiong) & is.na(foregroundGeneAboveCutOff)
                backPos <- is.na(foregroundGeneFalledInMotifReiong) & is.na(backgroundGeneAboveCutOff)

                fisherMtx <- matrix(0,nrow = 2,ncol = 2)
                fisherMtx[1,1] <- sum(!forePos)
                fisherMtx[1,2] <- sum(forePos)
                fisherMtx[2,1] <- sum(!backPosg)
                fisherMtx[2,2] <- sum(backPos)

                fisher.test(fisherMtx)$p.value
            })
            pValue[i,3] <- min(pvalueOfFisher)



        }

        pValue[is.na(pValue)] <- 1
        pValue[pValue>1] <- 1

        pValue[,4] <- p.adjust(pValue[,3],method = "fdr")

        score=-log10(pValue[,3])
        pValue<-data.frame(TF = tfName, Motif_enrichment = pValue[,1], Targt_gene_enrichment = pValue[,2], P_value = pValue[,3], FDR = pValue[,4])

        pValue <- pValue[order(score,decreasing = TRUE),]

        write.table(pValue,file = outputTFsEnrichTxt,quote = FALSE, row.names = FALSE,sep = "\t")



        .Object
    }
)

setMethod(
    f = "checkRequireParam",
    signature = "TFsEnrichInRegions",
    definition = function(.Object,...){
        if(is.null(.Object@inputList[["inputRegionBed"]])){
            stop("inputRegionBed is required.")
        }
        if(is.null(.Object@inputList[["inputForegroundGeneBed"]])){
            stop("inputForegroundGeneBed is required.")
        }
        if(is.null(.Object@inputList[["inputBackgroundGendBed"]])){
            stop("inputBackgroundGendBed is required.")
        }
        if(is.null(.Object@inputList[["inputRegionMotifBed"]])){
            stop("inputRegionMotifBed is required.")
        }

    }
)



setMethod(
    f = "checkAllPath",
    signature = "TFsEnrichInRegions",
    definition = function(.Object,...){
        checkFileExist(.Object@inputList[["inputRegionBed"]])
        checkFileExist(.Object@inputList[["inputForegroundGeneBed"]])
        checkFileExist(.Object@inputList[["inputBackgroundGendBed"]])
        checkFileExist(.Object@inputList[["inputRegionMotifBed"]])

    }
)

setMethod(
    f = "getReportValImp",
    signature = "TFsEnrichInRegions",
    definition = function(.Object,item,...){
        txt <- readLines(.Object@paramlist[["reportOutput"]])
        if(item == "total"){
            s<-strsplit(txt[1]," ")
            return(as.integer(s[[1]][1]))
        }
        if(item == "maprate"){
            s<-strsplit(txt[length(txt)],"% ")
            return(as.numeric(s[[1]][1])/100)
        }
        if(item == "detail"){
            return(txt)
        }
        stop(paste0(item," is not an item of report value."))
    }
)

setMethod(
    f = "getReportItemsImp",
    signature = "TFsEnrichInRegions",
    definition = function(.Object, ...){
        return(c("total","maprate","detail"))
    }
)



#' @name TFsEnrichInRegions
#' @title Test each TF is enriched in regions or not
#' @description
#'Test each TF is enriched in regions or not
#' @param GenBackgroundStep \code{\link{Step-class}} object scalar.
#' It has to be the return value of upstream process from \code{\link{genBackground}} and \code{\link{enrichGenBackground}}
#' @param FindMotifsInRegionsStep \code{\link{Step-class}} object scalar.
#' It has to be the return value of upstream process from \code{\link{findMotifsInRegions}} and \code{\link{enrichFindMotifsInRegions}}
#' @param RegionConnectTargetGeneStep \code{\link{Step-class}} object scalar.
#' It has to be the return value of upstream process from \code{\link{genBackground}} and \code{\link{enrichGenBackground}}
#' @param inputRegionBed \code{Character} scalar.
#' Regions BED file including foreground and background
#' @param inputForegroundGeneBed \code{Character} scalar.
#' Regions BED file including foreground and background
#' @param inputBackgroundGendBed \code{Character} scalar.
#' Regions BED file with motif candidates.
#' @param inputRegionMotifBed \code{Character} scalar.
#' Regions BED file with motif candidates.
#' @param outputTFsEnrichTxt \code{Character} scalar.
#' Regions BED file with motif candidates.
#' @param inputMotifWeights \code{Character} scalar.
#' Regions BED file with motif candidates.
#' Default: NULL (generate base on inputForegroundBed)
#' @param inputTFgeneRelMtx \code{Character} scalar.
#' Regions BED file with motif candidates.
#' Default: NULL (generate base on inputForegroundBed)
#' @param inputMotifTFTable \code{Character} scalar.
#' when "pwmfile" is set for motifRc, users use this argument to provid PWM file directory
#' @param ... Additional arguments, currently unused.
#' @details
#' Connect foreground and background regions to targetGene
#' @return An invisible \code{\link{EnrichTF-class}} object (\code{\link{Step-class}} based) scalar for downstream analysis.
#' @author Zheng Wei
#' @seealso
#' \code{\link{genBackground}}
#' \code{\link{findMotifsInRegions}}
#' \code{\link{tfsEnrichInRegions}}
#' @examples
#' setGenome("hg19")
#' foregroundBedPath <- system.file(package = "enrichTF", "extdata","testForeGround.bed")
#' gen <- genBackground(inputForegroundBed = foregroundBedPath)
#' conTG <- enrichRegionConnectTargetGene(gen)
#' findMotif <- enrichFindMotifsInRegions(gen,motifRc="integrate")
#' result <- enrichTFsEnrichInRegions(gen,findMotif,conTG)




setGeneric("enrichTFsEnrichInRegions",function(GenBackgroundStep,
                                               FindMotifsInRegionsStep,
                                               RegionConnectTargetGeneStep,
                                               inputRegionBed = NULL,
                                               inputForegroundGeneBed = NULL,
                                               inputBackgroundGendBed = NULL,
                                               inputRegionMotifBed = NULL,
                                               outputTFsEnrichTxt = NULL,
                                               inputMotifWeights = NULL,
                                               inputTFgeneRelMtx = NULL,
                                               inputMotifTFTable = NULL,
                                               ...) standardGeneric("enrichTFsEnrichInRegions"))



#' @rdname TFsEnrichInRegions
#' @aliases enrichMotifsInRegions
#' @export
setMethod(
    f = "enrichTFsEnrichInRegions",
    signature = "Step",
    definition = function(GenBackgroundStep,
                          FindMotifsInRegionsStep,
                          RegionConnectTargetGeneStep,
                          inputRegionBed = NULL,
                          inputForegroundGeneBed = NULL,
                          inputBackgroundGendBed = NULL,
                          inputRegionMotifBed = NULL,
                          outputTFsEnrichTxt = NULL,
                          inputMotifWeights = NULL,
                          inputTFgeneRelMtx = NULL,
                          inputMotifTFTable = NULL,
                          ...){
        allpara <- c(list(Class = "TFsEnrichInRegions", prevSteps = list(GenBackgroundStep,
                                                                         FindMotifsInRegionsStep,
                                                                         RegionConnectTargetGeneStep)),as.list(environment()),list(...))
        print(allpara)
        step <- do.call(new,allpara)
        invisible(step)
    }
)
#' @rdname TFsEnrichInRegions
#' @aliases tfsEnrichInRegions
#' @export
tfsEnrichInRegions <- function(inputRegionBed,
                               inputForegroundGeneBed,
                               inputBackgroundGendBed,
                               inputRegionMotifBed,
                               outputTFsEnrichTxt = NULL,
                               inputMotifWeights = NULL,
                               inputTFgeneRelMtx = NULL,
                               inputMotifTFTable = NULL,
                               ...){
    allpara <- c(list(Class = "TFsEnrichInRegions", prevSteps = list()),as.list(environment()),list(...))
    print(allpara)
    step <- do.call(new,allpara)
    invisible(step)
}