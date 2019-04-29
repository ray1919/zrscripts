library(shinyjs)
fluidPage(
  useShinyjs(),
  titlePanel("Check miRNA IDs with details"),
  tags$code("Author: Zhao Rui"),
  tags$code("Last update: 2017-02-17"),
  fluidRow(
    column(3, wellPanel(
      textAreaInput("mirs", "输入miRNA ID/Acc", "", resize = "vertical", height = 200),
      downloadButton('downloadData', 'Download Results'),
      checkboxGroupInput("cols", label = h3("Output columns"), 
                         choices = list("input_id", "mirna_id", "mirna_acc",
                                        "previous_mirna_id", "mature_name",
                                        "mature_acc, primer_in_stock" = "mature_acc",
                                        "previous_mature_id",
                                        "mirna_sequence", "mature_sequence"),
                         selected = c("input_id", "mature_name", "mature_acc", "mature_sequence")),
      tags$hr(),
      tags$code("miRBase Release 21."),
      tags$br(),
      tags$code("mir/miR case sensitive.")
    )),
    column(9,
          # verbatimTextOutput("value"),
          tableOutput("tbl")
    )
  )
)
