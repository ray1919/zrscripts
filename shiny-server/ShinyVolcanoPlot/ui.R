shinyUI(fluidPage(
    titlePanel("Volcano Plot"),
    sidebarLayout(
        sidebarPanel(
            fileInput('file1', 'Choose CSV File',
                      accept=c('text/csv', 
                               'text/comma-separated-values,text/plain', 
                               '.csv')),
            "Note: The input file should be a ASCII text file (comma, tab, semicolon separated),
                     containing three columns named ID, logFC and P.Value, respectivelly. You can download the default example from", a(href="https://raw.githubusercontent.com/onertipaday/ShinyVolcanoPlot/master/data/example.csv","here"),".",
            tags$hr(),
            radioButtons('sep', 'Separator',
                         c(Tab='\t',
                           Comma=','
                           ),
                         selected='\t'),
            checkboxInput("gene_names", "Show gene names", value = FALSE),
            tags$hr(),
            h4("Axes"),
            sliderInput("lfcr", "Log2(Fold-Change) Range:", 
                        -30, 30, value = c(-2.5, 2.5), 
                        step=0.5, animate=FALSE),
            sliderInput("lo", "-Log10(P-Value):", 
                        0, 15, value = 4, step=0.05),
            tags$hr(),
            h4("Cut-offs Selection"),
            sliderInput("hl", "P-Value Threshold:",
                        1, 6, value = 1.30, step=0.1),
            verbatimTextOutput('conversion'),
            sliderInput("vl", "log2(FC) Threshold:", 
                        0,2, value = 1, step=0.1),
            tags$hr(),
            downloadButton('downloadData', 'Download Selected DE genes list'),
            downloadButton('downloadPlot', 'Download Volcano Plot (PDF)')  
        ),
        mainPanel(
            tabsetPanel(type = "tabs",
                        tabPanel("ggPlot", plotOutput("ggplot", width = "720px", height = "720px")),
                        tabPanel("Cut-off Selected", dataTableOutput("tableOut"))
            )
        )
    )
))