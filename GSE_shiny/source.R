library(shiny)
library(org.Hs.eg.db)
library(org.Rn.eg.db)
library(org.Mm.eg.db)
library(DBI)
library(RMySQL)

get_gene_set <- function (type = c("`KEGG-PATHWAY`", "`GO-BP`", "`GO-MF`"), species = "human") {
  GS_CON <- dbConnect(RMySQL::MySQL(), user='gene_set', password='gene_set', dbname='gene_set', host='localhost')
  query <- paste("SELECT * FROM", type)
  retVal <- dbGetQuery(GS_CON, query)
  dbDisconnect(GS_CON)
  my_gene_set <- split(retVal$Gene_ID, retVal$id)
  return(my_gene_set)
}

id2symbol <- function(idList) {
  # convert gene id to gene symbol
  x <- org.Hs.egSYMBOL
  mapped_genes <- mappedkeys(x)
  xx <- as.list(x[mapped_genes])
  symbol <- xx[as.character(idList)]
  return(as.character(symbol))
}

validIds <- function(idList) {
  x <- org.Hs.egSYMBOL
  mapped_genes <- mappedkeys(x)
  return(intersect(mapped_genes,idList))
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

server <- function(input, output) {
  rv <- reactiveValues(gids = numeric(), gtbl=data.frame(), etbl=data.frame(),
                       link = "", xlsx="")
  output$gids <- renderText(paste("Input",length(rv$gids), "Gene ID(s)."))
  observeEvent(input$getGene, {
    rv$gids <- as.integer(unlist(strsplit(input$Gene_Ids,split = "\\D+")))
    rv$gids <- validIds(rv$gids) # make sure every id is valid and unique
    rv$gtbl <- get_gene_table(rv$gids)
    write.table(rv$gtbl,file = "www/gene_table.txt",sep="\t",row.names = F,
                quote=F)
    rv$link <- "gene_table.txt"
    output$link <- renderUI(tags$a(href=rv$link,target="_blank",
                                   paste("Download table as",rv$link)))
  })
  observeEvent(input$getRich, {
    rv$gids <- as.integer(unlist(strsplit(input$Gene_Ids,split = "\\D+")))
    withProgress(message = "Load libraries", value = .01,{
      library(qvalue)
      incProgress(amount = 0.01, "qvalue loaded.")
      library(DBI)
      library(RMySQL)
      incProgress(amount = 0.01, "RMySQL loaded.")
      library(DT)
      library(openxlsx)
      incProgress(amount = 0.01, "openxlsx loaded.")
      geneSet <- list()
      geneSet$GOBP <- get_gene_set("`GO-BP`")
      geneSet$GOMF <- get_gene_set("`GO-MF`")
      geneSet$KEGG <- get_gene_set("`KEGG-PATHWAY")
      TERM2NAME <- get_gene_set("`TERM2NAME")
      incProgress(amount = 0.02, "Gene sets loaded.")
      rv$gids <- validIds(rv$gids) # make sure every id is valid and unique
      if (length(rv$gids) >= input$minGSSize) {
        # rv$gtbl <- get_gene_table(rv$gids)
        incProgress(amount = 0.01, detail = "Calculating ...", "Gene table loaded.")
        retTbl <- data.frame()
        geneList <- rv$gids
        nPerm = input$nPerm
        minGSSize = input$minGSSize
        # 背景值18775统计自6出miR靶基因预测源数据中，出现在2个或以上数据库的基因数
        # background = 18775
        # 统计实际数据库中的基因背景值 HUMAN
        background = List()
        background$KEGG = 7018
        background$`GO-MF` = 14889
        background$`GO-BP` = 16413
        for (db_name in input$sources) {
          for (term_name in names(geneSet[[db_name]])) {
            interSets <- intersect(geneList,geneSet[[db_name]][[term_name]])
            
            # Chi-test
            a <- length(interSets)
            if (a < minGSSize)
              next
            
            b <- length(geneSet[[db_name]][[term_name]]) - a
            c <- length(geneList) - a
            d <- background[[db_name]] - a - b - c
            x <- matrix(c(a, b, c, d), ncol = 2, dimnames = list(
              c("IsTarget","NotTarget"), c("InNetwork","OutNetwork")))
            
            
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
            n <- length(geneList)
            k <- length(interSets)
            # 1-phyper(k-1,M,N-M,n)
            
            if (input$method == 1) {
              pval <- chisq.test(x, simulate.p.value = TRUE, B = nPerm)$p.value
            } else {
              pval <- phyper(k-1,M,N-M,n, lower.tail=FALSE)
            }
            
            if ( a/b < c/d ) {
              pval <- 0.95
              next
            }
            
            tblRes <- data.frame(Source = db_name, Term = term_name,
                                 Desc = TERM2NAME[[term_name]],
                                 Target_Cnt = length(geneList),
                                 Gene_Set_Size=a + b, Intersection_Size = a,
                                 Intersection_Genes=paste(id2symbol(interSets), collapse = ", "),
                                 P_Value=pval )
            retTbl <- rbind(retTbl, tblRes)
          }
          incProgress(amount = 0.9/length(input$sources), "Gene table loaded.")
        }
        enrichTbl <- retTbl
        p.adj <- p.adjust(enrichTbl$P_Value, method="BH")
        enrichTbl$p.adj <- p.adj
        if (input$qvalues) {
          # MIGHT ERROR
          qvalues <- qvalue(enrichTbl$P_Value, pi0.method="bootstrap")
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
}

ui <- shinyUI(fluidPage(
  fluidPage(
    theme="style.css",
    titlePanel("Human Gene Set Enrichment Analysis using Statistics Test"),
    fluidRow(
      column(4,
        # textInput(inputId = "Gene_Ids", label = "Gene IDs"),
        tags$label("Gene IDs"),
        tags$code("Entrez Gene IDs separated by space or new line."),
        tags$br(),
        tags$textarea(id="Gene_Ids", rows=10, cols=40, "")
      ),
      column(4,
        numericInput("minGSSize",label = "Min Intersection Gene Set Size", min = 1,
                   max = 88,value = 5, width = '227px'),
        checkboxGroupInput(inputId = "sources", label = "Term Sources:",
                           choices = c("GOBP","GOMF","KEGG"),
                           selected = c("GOBP","GOMF","KEGG")),
        radioButtons("method", label = "Statistic Method:",
                     choices = list("Chi-squared Test" = 1, "Hypergeometric Distribution Test" = 2), 
                     selected = 1),
        actionButton('getGene', 'Get Gene Table'),
        actionButton('getRich', 'Do Enrichment')
      ),
      column(4,
        sliderInput(inputId = "nPerm",label = "Num of permutaion:",
                   min = 100,max = 10000,value = 2000,step = 100),
        checkboxInput(inputId = "qvalues",label = "Add q values",value = F),
        tags$hr(),
        tags$code("KEGG-PATHWAY DB UPDATE: 2016-05-13"),
        tags$br(),
        tags$code("Gene-Ontology DB UPDATE: 2016-04-30"),
        tags$br(),
        tags$code("P adjust method: BH")
      )
    ),
    fluidRow(
      column(3, offset = 2,
        tags$strong(textOutput("gids"))
      )
    ),
    fluidRow(
      column(3,selectInput("source","Source:",c("All","GOBP","GOMF","KEGG")))
    ),
    fluidRow(
      htmlOutput("link"),
      DT::dataTableOutput("etbl")
    ),
    fluidRow(
      tableOutput("gtbl")
    )
  )
))

shinyApp(server = server, ui = ui)
