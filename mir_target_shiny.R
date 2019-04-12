library(shiny)
library(dplyr)
library(miRNAtap)
library(topGO)
library(org.Hs.eg.db)
library(openxlsx)
library(DT)

selection = function(x) TRUE 
# we do not want to impose a cut off, instead we are using rank information
allGO2genes = annFUN.org(whichOnto='BP', feasibleGenes = NULL,
                         mapping="org.Hs.eg.db", ID = "entrez")

ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      textAreaInput(inputId = "mir_text",
                    height = "200px",
                    label = "Input mature miRs (hsa-***-***):",
                    resize = "vertical"),
      actionButton("submit", "Submit"),
      downloadButton("download", "Download")
    ),
    
    
    mainPanel(
      textOutput("all_mir_list"),
      DT::dataTableOutput("GOBP_ENRICH")
    )
  )
)

server <- function(input, output, session) {
  mir_ary <- eventReactive(input$submit, {
    input$mir_text %>% strsplit(split = "\\s", perl = T) %>% unlist() %>% sub(pattern = "hsa-", replacement = "")
  }, ignoreNULL = F)
  
  output$all_mir_list <- renderText({
    mir_ary() %>% paste(collapse = ", ")
  })
  
  enrich_res <- eventReactive(input$submit, {
    withProgress(message = 'Calculation in progress',
                 detail = 'This may take a while...', value = 0, {
                   df <- data.frame()
                   for (i in 1:length(mir_ary())) {
                     mir <- mir_ary()[i]
                     predictions = getPredictedTargets(mir, species = 'hsa',
                                                       method = 'geom', min_src = 2)
                     rankedGenes = predictions[,'rank_product']
                     GOdata =  new('topGOdata', ontology = 'BP', allGenes = rankedGenes, 
                                   annot = annFUN.GO2genes, GO2genes = allGO2genes, 
                                   geneSel = selection, nodeSize=5)
                     resultKS <- runTest(GOdata, algorithm = "classic", statistic = "ks")
                     
                     df0 <- GenTable(GOdata, KS = resultKS, topNodes = resultKS@geneData["SigTerms"], numChar = 100) %>%
                       filter(KS < 0.05)
                     
                     if(nrow(df0) > 0){
                        df <- rbind(df, data.frame(miRNA = mir, df0))
                     }
                     incProgress(1/length(mir_ary()), mir)
                   }
                   df
                 })
  })
  
  output$GOBP_ENRICH <- DT::renderDataTable({
    enrich_res()
  }, 
  rownames = F,
  extensions = c("Buttons"), 
  options = list(dom = 'Bfrtip',
                 buttons = c('copy', 'csv', 'excel', 'pdf', 'print')
  ))
  
  output$download <- downloadHandler(filename = "GOBP_ENRICH.xlsx",
                                     content = function(file){
    wb <- createWorkbook(creator="AcebioX")
    addWorksheet(wb, sheetName = "GOBP_ENRICH")
    setColWidths(wb, sheet = "GOBP_ENRICH", cols = 1:ncol(enrich_res()),widths = "auto")
    writeDataTable(wb, sheet = "GOBP_ENRICH", x = enrich_res(), colNames = TRUE, rowNames = FALSE, withFilter = F)
    saveWorkbook(wb, file, overwrite = TRUE)
  })
}

shinyApp(ui, server)
