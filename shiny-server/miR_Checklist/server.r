library(dplyr)
library(DBI)
library(openxlsx)

rv <- reactiveValues(a = character())

function(input, output) {
  # output$value <- renderPrint({ input$cols })
  
  observeEvent({input$mirs;input$cols}, {
    rv$tbl <- data.frame()
    mirs <- strsplit(input$mirs, "\\n", perl = T) %>% unlist
    if (length(mirs) > 0) {
      con <- dbConnect(RMySQL::MySQL(), user = 'mirbase',
                       password='mirbase', host='localhost',db='mirbase21')
      
    withProgress(message = 'Calculation in progress',
      detail = 'Querying ...', value = 0, {
        for (i in 1:length(mirs)) {
          name <- mirs[i]
          if (name == "") { next() }
          # print(name)
          if (grepl(pattern = "MIMAT", x = name)) {
            query1 <- paste("select i.mirna_acc, i.mirna_id, i.previous_mirna_id,
              a.mature_acc, a.mature_name, a.previous_mature_id,
              i.sequence mirna_sequence,
              substring(i.sequence, p.mature_from, p.mature_to - p.mature_from + 1) mature_sequence
              from mirna i, mirna_mature a, mirna_pre_mature p
              where (i.mirna_acc = '", name, "' or a.mature_acc = '", name, "')
              and a.auto_mature = p.auto_mature
              and p.auto_mirna = i.auto_mirna", sep = "")
          } else {
            query1 <- paste("select i.mirna_acc, i.mirna_id, i.previous_mirna_id,
            a.mature_acc, a.mature_name, a.previous_mature_id,
            i.sequence mirna_sequence,
            substring(i.sequence, p.mature_from, p.mature_to - p.mature_from + 1) mature_sequence
            from mirna i, mirna_mature a, mirna_pre_mature p
            where (a.mature_name = '", name, "' or i.mirna_id = '", name, "')
            and a.auto_mature = p.auto_mature
            and p.auto_mirna = i.auto_mirna", sep = "")
          }
          res <- dbFetch(dbSendQuery(con, query1))
          if (nrow(res) > 0) {
            res$input_id <- name
            rv$tbl <- rbind(rv$tbl, res[,input$cols] %>% unique)
          } else {
            query2 <- paste("select i.mirna_acc, i.mirna_id, i.previous_mirna_id,
            a.mature_acc, a.mature_name, a.previous_mature_id,
            i.sequence mirna_sequence,
            substring(i.sequence, p.mature_from, p.mature_to - p.mature_from + 1) mature_sequence
            from mirna i, mirna_mature a, mirna_pre_mature p
            where a.previous_mature_id regexp '[[:<:]]", name, "[[:>:]]'
            and a.previous_mature_id not regexp '", name, "\\\\*'
            and a.auto_mature = p.auto_mature
            and p.auto_mirna = i.auto_mirna", sep = "")
            res2 <- dbFetch(dbSendQuery(con, query2))
            if (nrow(res2) > 0) {
              res2$input_id <- name
              rv$tbl <- rbind(rv$tbl, res2[,input$cols] %>% unique)
            } else {
              query3 <- paste("select i.mirna_acc, i.mirna_id, i.previous_mirna_id,
              a.mature_acc, a.mature_name, a.previous_mature_id,
              i.sequence mirna_sequence,
              substring(i.sequence, p.mature_from, p.mature_to - p.mature_from + 1) mature_sequence
              from mirna i, mirna_mature a, mirna_pre_mature p
              where i.previous_mirna_id regexp '[[:<:]]", name, "[[:>:]]'
              and i.previous_mirna_id not regexp '", name, "\\\\*'
              and a.auto_mature = p.auto_mature
              and p.auto_mirna = i.auto_mirna", sep = "")
              res3 <- dbFetch(dbSendQuery(con, query3))
              if (nrow(res3) > 0) {
                res3$input_id <- name
                rv$tbl <- rbind(rv$tbl, res3[,input$cols] %>% unique)
              } else {
                rv$tbl <- rbind(rv$tbl, c(name, NA,NA,NA,NA,NA,NA,NA,NA))
              }
            }
          }
          incProgress(1/length(mirs), name)
        }
      })
    dbDisconnect(con)
    if ("mature_acc" %in% colnames(rv$tbl) ) {
      rv$tbl$primer_in_stock <- NA
      con2 <- dbConnect(RMySQL::MySQL(), user = 'ctnet',
                      password='ctnet', host='localhost',db='ctnet')
      for (i in 1:nrow(rv$tbl)) {
        acc <- rv$tbl$mature_acc[i]
        query4 <- paste("SELECT * FROM `primer` WHERE `gene_id` = '", acc, "';", sep = "")
        res4 <- dbFetch(dbSendQuery(con2, query4))
        if (nrow(res4) > 0) {
          rv$tbl$primer_in_stock[i] <- "Yes"
        }else {
          rv$tbl$primer_in_stock[i] <- "No"
        }
      }
      dbDisconnect(con2)
    }
    }
    output$tbl <- renderTable({rv$tbl})
  })
  

  output$downloadData <- downloadHandler(
    filename = function() {
      rv$wb <- createWorkbook(creator="CT Bioscience")
      options("openxlsx.borderColour" = "#4F80BD")
      options("openxlsx.borderStyle" = "thin")
      modifyBaseFont(rv$wb, fontSize = 10, fontName = "Calibri")
      headSty <- createStyle(fgFill="#DCE6F1", halign="center",
                             border = "TopBottomLeftRight")
      addWorksheet(rv$wb, sheetName = "miNRA Checklist", zoom = 150)
      writeDataTable(rv$wb, sheet = "miNRA Checklist", x = rv$tbl,
                     colNames = T, rowNames = F, tableStyle = "TableStyleLight10")
      setColWidths(rv$wb, "miNRA Checklist", widths = "auto", cols = 1:length(rv$tbl))
      paste(Sys.Date(), '.xlsx', sep='') 
    },
    content = function(file) {
      saveWorkbook(rv$wb, file, overwrite = TRUE)
    }
  )
}
