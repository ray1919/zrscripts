shinyUI(fluidPage(
  theme="style.css",
  titlePanel("Gene Set Enrichment Analysis using Statistics Test"),
  tags$code("Update: 2017/1/5"),
  fluidRow(
    column(4,
           # textInput(inputId = "Gene_Ids", label = "Gene IDs"),
           selectInput(inputId = "input_type", label = "Input Type:",
                       choices = c("Gene symbol","Gene ID")),
           selectInput(inputId = "organism", label = "Organism:",
                       choices = c("Human","Mouse", "Rat")),
           tags$label("Gene Symbol / IDs"),
           tags$code("Entrez Gene Symbol / IDs separated by space or new line."),
           tags$br(),
           tags$textarea(id="Gene_Ids", rows=5, cols=40, "")
    ),
    column(4,
           numericInput("minGSSize",label = "Min Intersection Gene Set Size", min = 1,
                        max = 88,value = 5, width = '227px'),
           checkboxGroupInput(inputId = "sources", label = "Term Sources:",
                              choices = c("GOBP","GOMF","KEGG"),
                              selected = c("GOBP","GOMF","KEGG")),
           radioButtons("method", label = "Statistic Method:",
                        choices = list("Fisher Exact Test" = 1, "Hypergeometric Distribution Test" = 2), 
                        selected = 1),
           actionButton('getGene', 'Get Gene Table'),
           actionButton('getRich', 'Do Enrichment')
    ),
    column(4,
           sliderInput(inputId = "nPerm",label = "Num of permutaion:",
                       min = 100,max = 10000,value = 2000,step = 100),
           checkboxInput(inputId = "qvalues",label = "Add q values",value = F),
           tags$label("Background Genes"),
           tags$br(),
           tags$textarea(id="backgrounds", rows=5, cols=40, ""),
           tags$hr(),
           tags$code("KEGG-PATHWAY DB UPDATE: 2017-03-27"),
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
))