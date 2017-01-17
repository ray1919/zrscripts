library(shiny)
# library(org.Hs.eg.db)
# library(org.Rn.eg.db)
# library(org.Mm.eg.db)
library(DBI)
library(RMySQL)

get_gene_set <- function (type = c("`KEGG-PATHWAY`", "`GO-BP`", "`GO-MF`"), species = "Human") {
  GS_CON <- dbConnect(RMySQL::MySQL(), user='gene_set', password='gene_set', dbname='gene_set', host='localhost')
  query <- paste("SELECT * FROM", type)
  retVal <- dbGetQuery(GS_CON, query)
  dbDisconnect(GS_CON)
  my_gene_set <- split(retVal$Gene_ID, retVal$id)
  return(my_gene_set)
}

get_gene_set_background <- function (type = c("`KEGG-PATHWAY`", "`GO-BP`", "`GO-MF`"), species = "Human") {
  GS_CON <- dbConnect(RMySQL::MySQL(), user='gene_set', password='gene_set', dbname='gene_set', host='localhost')
  tax_id <- list(Human = 9606, Mouse = 10090, Rat = 10116) 
  query <- paste("SELECT count(DISTINCT n.GeneID) cnt FROM ", type,
                 " g LEFT JOIN ncbi.gene_info n on n.GeneID = g.`Gene_ID`
                 WHERE n.tax_id = ", tax_id[[species]])
  retVal <- dbGetQuery(GS_CON, query)
  dbDisconnect(GS_CON)
  return(retVal$cnt)
}

id2symbol <- function(idList) {
  # convert gene id to gene symbol
  # x <- org.Hs.egSYMBOL
  # mapped_genes <- mappedkeys(x)
  # xx <- as.list(x[mapped_genes])
  # symbol <- xx[as.character(idList)]
  # return(as.character(symbol))
  DB_CON <- dbConnect(RMySQL::MySQL(), user='ncbi', password='ncbi', dbname='ncbi', host='localhost')
  query <- paste("SELECT `Symbol` FROM `gene_info` WHERE GeneID in (",
                 paste(idList, collapse=","),
                 ") ORDER BY field(GeneID, ", paste(idList, collapse=","), ")", sep="")
  retVal <- dbGetQuery(DB_CON, query)
  dbDisconnect(DB_CON)
  return(as.character(retVal$Symbol))
}

validIds <- function(idList) {
  # x <- org.Hs.egSYMBOL
  # mapped_genes <- mappedkeys(x)
  DB_CON <- dbConnect(RMySQL::MySQL(), user='ncbi', password='ncbi', dbname='ncbi', host='localhost')
  query <- paste("SELECT `GeneID` FROM `gene_info`")
  retVal <- dbGetQuery(DB_CON, query)
  dbDisconnect(DB_CON)
  all_gids <- as.integer(retVal$GeneID)
  return(intersect(all_gids,idList))
}

get_gene_table <- function (idList) {
  if (length(idList) < 1) {
    return(data.frame())
  }
  DB_CON <- dbConnect(RMySQL::MySQL(), user='ncbi', password='ncbi', dbname='ncbi', host='localhost')
  query <- paste("SELECT `Symbol`, `GeneID`, `description`, t.name_txt Species, `chromosome`, `type_of_gene`
    FROM `gene_info` g
    LEFT JOIN taxdump_names t on t.tax_id = g.tax_id
    AND name_class = \"scientific name\"
    WHERE GeneID in (",
                 paste(idList, collapse=","),
                 ") ORDER BY Symbol", sep = "")
  retVal <- dbGetQuery(DB_CON, query)
  dbDisconnect(DB_CON)
  retVal$GeneID <- as.integer(retVal$GeneID)
  return(retVal)
}

convert2gids <- function(symbols, organism) {
  DB_CON <- dbConnect(RMySQL::MySQL(), user='ncbi', password='ncbi', dbname='ncbi', host='localhost')
  tax_id <- list(Human = 9606, Mouse = 10090, Rat = 10116) 
  query <- paste("SELECT `GeneID` FROM `gene_info` WHERE tax_id = ", tax_id[[organism]],
                 " AND Symbol in (\"",
                 paste(symbols, collapse = "\",\""), "\") ORDER BY Symbol",
                 sep = "")
  retVal <- dbGetQuery(DB_CON, query)
  dbDisconnect(DB_CON)
  retVal$GeneID <- as.integer(retVal$GeneID)
  return(retVal$GeneID)
}

shinyServer(function(input, output) {
  rv <- reactiveValues(gids = numeric(), gtbl=data.frame(), etbl=data.frame(),
                       link = "", xlsx="", back_gids = numeric())
  
  
    output$gids <- renderText(paste("Input",length(rv$gids), "Gene(s)."))
    observeEvent(input$getGene, {
      if (input$input_type == "Gene ID") {
        rv$gids <- as.integer(unlist(strsplit(input$Gene_Ids,split = "\\D+")))
        rv$back_gids <- as.integer(unlist(strsplit(input$backgrounds, split = "\\D+")))
      } else {
        symbols <- as.character(unlist(strsplit(input$Gene_Ids,split = "\\s+")))
        back_syms <- as.character(unlist(strsplit(input$backgrounds,split = "\\s+")))
        org <- input$organism
        rv$gids <- convert2gids(symbols, org)
        rv$back_gids <- convert2gids(back_syms, org)
      }
      rv$gids <- validIds(rv$gids) # make sure every id is valid and unique
      rv$back_gids <- validIds(rv$back_gids) # make sure every id is valid and unique
      rv$gtbl <- get_gene_table(rv$gids)
      write.table(rv$gtbl,file = "www/gene_table.txt",sep="\t",row.names = F,
                  quote=F)
      rv$link <- "gene_table.txt"
      output$link <- renderUI(tags$a(href=rv$link,target="_blank",
                                     paste("Download table as",rv$link)))
    })

  observeEvent(input$getRich, {
    # rv$gids <- as.integer(unlist(strsplit(input$Gene_Ids,split = "\\D+")))
    withProgress(message = "Load libraries", value = .01,{
      # library(qvalue)
      # incProgress(amount = 0.01, "qvalue loaded.")
      library(DT)
      library(openxlsx)
      incProgress(amount = 0.01, "openxlsx loaded.")
      geneSet <- list()
      geneSet$GOBP <- get_gene_set("`GO-BP`")
      geneSet$GOMF <- get_gene_set("`GO-MF`")
      geneSet$KEGG <- get_gene_set("`KEGG-PATHWAY`")
      TERM2NAME <- get_gene_set("`TERM2NAME`")
      incProgress(amount = 0.02, "Gene sets loaded.")
      # rv$gids <- validIds(rv$gids) # make sure every id is valid and unique
      # print(rv$gids)
      if (length(rv$gids) >= input$minGSSize) {
        # rv$gtbl <- get_gene_table(rv$gids)
        incProgress(amount = 0.01, detail = "Calculating ...", "Gene table loaded.")
        retTbl <- data.frame()
        geneList <- rv$gids
        nPerm = input$nPerm
        minGSSize = input$minGSSize
        # print(rv$gids)
        # 背景值18775统计自6出miR靶基因预测源数据中，出现在2个或以上数据库的基因数
        # background = 18775
        # 统计实际数据库中的基因背景值 HUMAN
        org <- input$organism
        background = list()
        background$KEGG <- get_gene_set_background(type = "`KEGG-PATHWAY`", species = org)
        background$`GOMF` <- get_gene_set_background(type = "`GO-MF`", species = org)
        background$`GOBP` <- get_gene_set_background(type = "`GO-BP`", species = org)

        for (db_name in input$sources) {
          # print(length(names(geneSet[[db_name]])))
          for (term_name in names(geneSet[[db_name]])) {
            B <- rv$back_gids
            S <- geneSet[[db_name]][[term_name]]
            L <- geneList

            interSets <- intersect(L, S)
            
            # Fisher Exact Test
            a <- length(intersect(S, L))
            if (a < minGSSize)
              next
            
            b <- length(intersect(setdiff(S, L), B))
            c <- length(setdiff(L, S))
            d <- length(setdiff(setdiff(B, L), S))
            x <- matrix(c(a, b, c, d), ncol = 2, dimnames = list(
              c("InList","OutList"), c("InGeneSet","OutGeneSet")))

            # hyper test
            # 简单点说，超几何分布就是有限样本的无放回抽样。不同于有放回抽样的二项分布（每次贝努里试验成功概率是一样的），每次的概率不相等。 随机变量X的超几何概率分布：
            # f(k,N,M,n) = C(k,M)*C(n-k,N-M)/C(n,N)
            # N = size of population
            # M = # of items in population with property "E"
            # N-M = # of items in population without property "E"
            # n = number of items sampled
            # k = number of items in sample with property "E"
            N <- background[[db_name]]
            M <- length(geneSet[[db_name]][[term_name]])
            n <- length(L)
            k <- length(intersect(L, S))
            # 1-phyper(k-1,M,N-M,n)
            
            if (input$method == 1) {
              pval <- fisher.test(x, simulate.p.value = TRUE, B = nPerm)$p.value
            } else {
              pval <- phyper(k-1,M,N-M,n, lower.tail=FALSE)
            }
            
            if ( a/b < c/d ) {
              pval <- 0.95
              next
            }
            # print(x)
            tblRes <- data.frame(Source = db_name, Term = term_name,
                                 Desc = TERM2NAME[[term_name]],
                                 Target_Cnt = length(L),
                                 Gene_Set_Size=length(S), Intersection_Size = length(interSets),
                                 Intersection_Genes=paste(id2symbol(interSets), collapse = ", "),
                                 P_Value=pval )
            retTbl <- rbind(retTbl, tblRes)
          }
          incProgress(amount = 0.9/length(input$sources), "Gene table loaded.")
        }
        enrichTbl <- retTbl
        p.adj <- p.adjust(enrichTbl$P_Value, method="fdr")
        enrichTbl$FDR <- p.adj
        if (input$qvalues) {
          # MIGHT ERROR
          qvalues <- p.adjust(enrichTbl$P_Value, method="BH")
          enrichTbl$qvalue <- qvalues$qvalues
        }
        rv$etbl <- enrichTbl
        write.table(rv$etbl,file = "www/enrichment.txt",sep="\t",row.names = F,
                    quote=F)
        rv$link <- "enrichment.txt"
        setProgress(0.98, message = "Enrichment DONE.", detail = "saving results.")
        
        wb <- createWorkbook(creator="CT Bioscience")
        options("openxlsx.borderColour" = "#4F80BD")
        options("openxlsx.borderStyle" = "thin")
        modifyBaseFont(wb, fontSize = 12, fontName = "Calibri")
        addWorksheet(wb, sheetName = "Enrichment")
        setColWidths(wb, sheet = 1, cols = "A", widths = 8)
        setColWidths(wb, sheet = 1, cols = "B", widths = 15)
        setColWidths(wb, sheet = 1, cols = "C", widths = 50)
        setColWidths(wb, sheet = 1, cols = "D", widths = 13)
        setColWidths(wb, sheet = 1, cols = "E", widths = 18)
        setColWidths(wb, sheet = 1, cols = "F", widths = 18)
        setColWidths(wb, sheet = 1, cols = "G", widths = 80)
        setColWidths(wb, sheet = 1, cols = "H", widths = 16)
        setColWidths(wb, sheet = 1, cols = "I", widths = 16)
        freezePane(wb, sheet = 1, firstRow = TRUE,
                   firstCol = F) ## freeze first row and column
        headSty <- createStyle(fgFill="#DCE6F1", halign="center",
                               border = "TopBottomLeftRight")
        writeData(wb, 1, x = enrichTbl, startCol = "A", startRow=1, borders="rows",
                  headerStyle = headSty)
        saveWorkbook(wb, "www/enrichment.xlsx", overwrite = TRUE)
        rv$xlsx <- "enrichment.xlsx"
        
        setProgress(1, message = "JOB DONE.")
        output$link <- renderUI(tags$p("Download table as",
                                       tags$a(href=rv$link, target="_blank", rv$link),
                                       "or",
                                       tags$a(href=rv$xlsx, target="_blank", rv$xlsx)))
      }
    })
  })
  output$gtbl <- renderTable(rv$gtbl)
  # DT::copySWF('www')
  output$etbl <- DT::renderDataTable(DT::datatable({
    data <- rv$etbl
    if (input$source != "All") {
      data <- data[data$Source == input$source,]
    }
    data}),
    selection = list(target = 'row+column')
  )
})