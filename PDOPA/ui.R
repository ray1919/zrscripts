library(shiny)

fluidPage(
  theme="style.css",
  titlePanel("PCR Data Online Processing App"),
  tags$code("Last update: 2017-01-16"),
  sidebarLayout(
    sidebarPanel(
      fileInput('files', 'Choose PCR Template & Data Files', multiple = T,
                accept=c('.xlsx', ".txt")),
      tags$hr(),
      helpText("将罗氏480导出的CT/TM文本文件及Excel模板文件一同上传。"),
      helpText("上传的文件显示在右侧窗口。"), 
      helpText("需要在分析中忽略的基因名称用\"[SKIP]\"表示。"),
      helpText("不规则排版顺序，人工编辑的芯片结果按照表5的格式保存在模板文件中，按照“已有数据表”模式进行分析。"),
      tags$a('模板下载', href="PCR_Layout_Template.xlsx"),
      radioButtons('task', '任务',
                   c(常规分析='routine',
                     仅导出数据='data_only',
                     已有数据表='data_ready'),
                   'routine'),
      actionButton('processData', 'Run'),
      downloadButton('downloadData', 'Download')
    ),
    mainPanel(
      textOutput('text'),
      tableOutput('contents'),
      plotOutput('plot')
    )
  )
)