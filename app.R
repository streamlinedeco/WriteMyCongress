library(dplyr)
library(knitr)
library(jsonlite)
library(lubridate)
library(readr)
library(rmarkdown)
library(shiny)
library(shinyjs)
library(shinythemes)
library(tidyr)

source("functions.R")
president <- data.frame(title = "President",
                        firstName = "Donald", 
                        lastName = "Trump", 
                        phone = "", 
                        street = "1600 Pennsylvania Ave. NW", 
                        city = "Washington", 
                        state = "D.C.", 
                        zip = "20500", 
                        officeList = "President Trump - White House", 
                        shortName = "President Trump",
                        stringsAsFactors = F)

ui <- 
  navbarPage(
    
    
    # Application title
    header = 
      tags$head(
        tags$style(
          HTML(
            "body{
            width:100%;
            max-width:950px;
            margin-left:auto;
            margin-right:auto;
            background-color: #ffffff;
            box-shadow: 0 0 10px;
            height:100%;
            padding-bottom: 5%;
            padding-top: 90px;
          }
          .navbar{
            margin-left:auto;
            margin-right:auto;
            width:100%;
            max-width:960px;
            box-shadow: 0 2px 5px;
          }
          @media (min-width:960px){
            html{
              background-image: linear-gradient(135deg,rgba(240,240,240,0.3), rgba(240,240,240,0.35));
            }
          }
          "
          )
        ),
        includeScript("analytics.js")
      ),
    
    windowTitle = "WriteMyCongress",
    title = "WriteMyCongress",
    theme = shinytheme("flatly"),
    position = "fixed-top",
    footer = 
      fluidRow(
        column(width = 12,
               align = "center",
               style = "font-size:9pt",
               HTML("<br><br>This project is free and open source under GNU APGLv3.<br>Source code can be found <a href = 'https://github.com/streamlinedeco/WriteMyCongress'>here</a>.<br>For more information please contact <a href = mailto:WriteMyCongress@outlook.com>WriteMyCongress@outlook.com</a><br>Congressional data from <a href = https://github.com/unitedstates>@unitedstates</a> & <a href = https://github.com/TheWalkers/congress-legislators>@TheWalkers</a>.<br>The closest district office to your address is found using the <a href = http://www.phoneyourrep.com/>phoneyourrep.com</a> <a href = https://github.com/msimonborg/phone-your-rep-api>API</a>.<br>Geocoding uses the MapQuest Open Streets Mapping API.")
        )
      ),
    collapsible = TRUE,
    # Sidebar with a slider input for number of bins 
    tabPanel("Write",
             style = "width:80%; margin-right:auto; margin-left:auto", 
             useShinyjs(),
             # verbatimTextOutput("debug"),
             h2("Who are we?"),
             p("WriteMyCongress was created to simplifiy the process of writing to the people who represent you in Congress. Once you enter your address we'll retreive your members of Congress, and you can choose to write letters to their Washington office or their closest local office. Type your message and then we'll take care of getting their addresses and formatting all the letters, giving you a PDF to print and drop in the mail."),
             h2("Who are you?"),
             p("All fields except phone number are required, if you do provide a phone number it will be included in your return address on the letters. No data is stored."),
             fluidRow(style = "margin-right:auto; margin-left:auto",
                      column(width = 6,
                             textInput("conName",
                                       "Your Name:",
                                       width = '100%'),
                             textInput("conPhone",
                                       "Phone (optional):",
                                       width = '100%'),
                             textInput("conStreet",
                                       "Street:",
                                       width = '100%')),
                      column(width = 6,
                             textInput("conCity",
                                       "City:",
                                       width = '100%'),
                             textInput("conState",
                                       "State:",
                                       width = '100%'),
                             textInput("conZip",
                                       "Zip:",
                                       width = '100%')
                      )
             ),
             fluidRow(
               h2("What do you want to say?"),
               column(width = 12,
                      textAreaInput2("letterBody",
                                     label = "",
                                     placeholder = "Type your message here (salutation & signature will be added):",
                                     width = '100%')
               )
             ),
             fluidRow(
               h2("Where do you want to send your letters?"),
               column(width = 12,
                      align = "center",
                      selectizeInput("offices",
                                     label = "",
                                     choices =  list("Enter your address to find your members of Congress" = ""),
                                     multiple = TRUE,
                                     width = '60%')
               )
             ),
             fluidRow(
               align = "center",
               disabled(downloadButton("downloadLetters",
                                       "Get My Letters"))
             )
    ),
    # tabPanel("Map the Offices",
    #          p("Coming soon.")),
    tabPanel("About",
             style = "width:80%; margin-right:auto; margin-left:auto", 
             h2("Thank you for being an active citizen!"),
             br(),
             h3("The Purpose"),
             p("The more engaged each citizen is the more accurately the government will represent our best interests. To that end this site was created to make it easier for anyone,", span("regardless of ideology or affiliation, ", style = 'font-style: italic'), "to write letters to their members of Congress (MoC). There shouldn't be any need to worry about formatting the letter, finding addresses, or printing the same letter 3 times with different names and addresses. Instead, just type your message, choose where you want to send your letter and a PDF is generated that contains a formatted letter addressed to each chosen MoC, about as easy as it can be."),
             h3("Upcoming Features"),
             HTML("<p>If you have any ideas for how to make this tool better please pass them along to <a href = mailto:writemycongress@outlook.com>WriteMyCongress@outlook.com</a>. Currently planning additions to WriteMyCongress include <ul><li>A postcard template in addition to the letter template</li><li>An example of a generated letter</li><li>An option to write to Congressional committees in addition to members of Congress</li><li>The ability to generate a bookmark with your addresses pre-populated</li></ul> Because this tool is meant for anyone there will not be any sample text provided for issues, but feel free to copy and paste sample text from anywhere into the form."),
             h3("About the Author"),
             p("Joe Shannon is an environmental scientist and researcher interested in ecohydrology. Part of his work is creating tools to make organizing and analyzing data more straightforward, transparent, and reproducible. After sharing the addresses of my members of Congress with friends a few times, and making three copies of my own letters, I realized I could take my ecological tools and make a civics tool.")
    )
  )
# Define server logic required to draw a histogram
server <- function(input, output, session) {
  # output$debug <- renderPrint({input$conPhone})
  
  addresses <- reactive({
    if(input$conStreet != "" &&
       input$conCity != "" &&
       input$conState != "" &&
       nchar(input$conZip) >= 5){
      fetch_MoC(zip = input$conZip,
                street = input$conStreet,
                city = input$conCity,
                state = input$conState)}
  })
  
  observe({
    toggleState(id = "downloadLetters", 
           input$conName != "" &&
             input$conStreet != "" &&
             input$conCity != "" &&
             input$conState != "" &&
             input$conZip != "" &&
             input$conName != " " &&
             input$conStreet != " " &&
             input$conCity != " " &&
             input$conState != " " &&
             input$conZip != " " &&
             input$letterBody != "" &&
             input$offices != ""
           )
  })
  
  observe({
    if(input$conStreet != "" &&
       input$conCity != "" &&
       input$conState != "" &&
       input$conStreet != " " &&
       input$conCity != " " &&
       input$conState != " " &&
       input$conZip != ""){
      updateSelectizeInput(session,
                           "offices",
                           choices = c("Select your members of Congress" = "",
                                       addresses()$officeList,
                                       president$officeList[1]))
    }
  })
  
  output$downloadLetters <- 
    downloadHandler(
      filename = "WriteMyCongress.pdf",
      content = function(file){
        
        # oldWD <- getwd()
        # setwd(tempdir())
        # on.exit(setwd(oldWD))
        
        ADDRESSES <- as.data.frame(addresses())
        if(president$officeList %in% input$offices){
          ADDRESSES <- 
            bind_rows(
              ADDRESSES,
              president
            )
        }
        
        tempLetters <- file.path(tempdir(), "Form_Letter.Rmd")
        file.copy("Form_Letter.Rmd", tempLetters, overwrite = T)
        
        reps <- input$offices
        nLetters <- length(reps)
        letters <- character(nLetters)
        for(I in 1:nLetters){
          repInfo <- ADDRESSES[ADDRESSES$officeList == reps[I],]
          repShortNames <- unique(ADDRESSES[ADDRESSES$officeList %in% input$offices, "shortName"])
          repInfo$cc <- paste(repShortNames[repShortNames != repInfo$shortName],
                              collapse = "; ")
          letters[I] <-
            readr::read_file(
              rmarkdown::render("Form_Letter.Rmd",
                                output_format = "md_document",
                                params = list(
                                  letterBody = input$letterBody,
                                  constituentName = input$conName,
                                  constituentStreet = input$conStreet,
                                  constituentCity = input$conCity,
                                  constituentState = input$conState,
                                  constituentZip = input$conZip,
                                  constituentPhone = input$conPhone,
                                  repTitle = repInfo$title,
                                  repFirstName = repInfo$firstName,
                                  repLastName = repInfo$lastName,
                                  repStreet = repInfo$street,
                                  repCity = repInfo$city,
                                  repState = repInfo$state,
                                  repZip = repInfo$zip,
                                  repCC = repInfo$cc,
                                  repPhone = repInfo$phone
                                ),
                                envir = new.env(parent = globalenv())
              )
            )
          
        }
        
        holding <- tempfile(tmpdir = getwd())
        
        write_file(knit(text = paste("\\pagenumbering{gobble}",
                                     letters,
                                     collapse = "\\newpage ")),
                   path = holding)
        rmarkdown::render(input = holding, 
               output_format = "pdf_document", 
               output_file = "pdfOut.pdf")
        file.remove(holding)
        file.rename("pdfOut.pdf", file)
        # setwd(oldWD)
      }
    ) 
}

# Run the application 
shinyApp(ui = ui, server = server)

