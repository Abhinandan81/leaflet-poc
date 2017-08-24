library(shiny)
library(leaflet)
library(shinyjs)


shinyUI(fluidPage(
  
  shinyjs::useShinyjs(), # Setup shinyjs 
  
  tags$head(# Include our custom CSS
    includeCSS("www/styles.css")),
  
  navbarPage("POC", id = "nav",
             
             tabPanel(
               "Production Overview",
               div(
                 class = "outer",
                 div( id = "main_map", class = "map_init",
                 leafletOutput("map")),
                 
                 absolutePanel(
                   id = "controls",
                   class = "panel panel-default",
                   fixed = TRUE,
                   draggable = TRUE,
                   top = 60,
                   left = "auto",
                   right = 20,
                   bottom = "auto",
                   width = 400,
                   height = "auto",
                   
                   radioButtons("prod-output", label = "Cumulative Monthly Production", choices = list("All" = "All" ,"More than 15k" = "15000", "In between 8k - 15k" = "8000",
                                                                                                             "Less than 8k" ="7999"), selected = "All"),
                   tags$hr(),
                   
                   uiOutput("site_wise_products")
                 ),#absolutePanel
                 
                 tags$hr(),
  
                 plotOutput("monthwise-production")
               )#div
             )#tabPanel
             )#navbarPage
  )#fluidPage
  )