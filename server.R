library(shiny)
library(leaflet)
library(RColorBrewer)
library(dplyr)
library(readxl)
library(tidyr)
library(ggplot2)
library(shinyjs)


shinyServer(function(input, output, session) {
  site_details <- read_excel("site_details.xlsx", sheet = "Site")
  
  site_wise_product_details <- read_excel("site_details.xlsx", sheet = "siteWiseProducts")

  getColor <- function(monthly_outcome) {
    sapply(monthly_outcome, function(monthly_outcome) {
      if (monthly_outcome >= 15000) {
        "green"
      } else if (monthly_outcome >= 8000 &
                 monthly_outcome < 15000) {
        "orange"
      } else {
        "red"
      }
    })
  }
  
  output$map <- renderLeaflet({
    production_details <- input$`prod-output`
    
      if(production_details == "15000"){
        site_details <- filter(site_details, monthly_outcome >= 15000)
      } else if(production_details == "8000"){
        site_details <- filter(site_details, monthly_outcome >= 8000 & monthly_outcome < 15000)
      } else if(production_details == "7999"){
        site_details <- filter(site_details, monthly_outcome < 8000)
      }
  
    
    icons <- awesomeIcons(
      icon = 'medkit',
      iconColor = 'white',
      library = 'ion',
      markerColor = getColor(site_details$monthly_outcome)
    )
    
    leaflet(site_details) %>% setView(lng = 12.5674,
                                      lat = 41.8719,
                                      zoom = 3) %>%
      addProviderTiles(providers$Esri.DeLorme,
                       options = providerTileOptions(noWrap = TRUE))  %>%
      addAwesomeMarkers(icon = icons, layerId = ~ site_short_name) %>%
      addLegend(
        position = "bottomleft",
        colors = c("green", "orange", "red"),
        labels = c(">= 15000", ">= 8000 & < 15000", "< 8000"),
        title = "Monthly production"
      )
  })
  
  # When mousehover on a map, show a popup with basic site info
  observe({
    leafletProxy("map") %>% clearPopups()
    event <- input$map_marker_mouseover
    
    if (is.null(event))
      return()
    
    isolate({
      fetchBasicSiteDetails(event$id, event$lng, event$lat)
    })
  })
  
  #fetching basic site details
  fetchBasicSiteDetails <- function(site_name, lng, lat) {
    full_site_name <-
      unique(site_details %>% filter(site_short_name == site_name) %>% select(site_full_name))
    
    content <- as.character(tagList(strong("Site Name:"),
                                    full_site_name,
                                    tags$br()))
    
    leafletProxy("map") %>% addPopups(lng, lat, content, layerId = site_name)
    
  }
  
  #on mouce click
  output$site_wise_products <- renderUI({
    
    leafletProxy("map") %>% clearPopups()
    event <- input$map_marker_click
    
    if (is.null(event))
      return(NULL)
    
      products_at_site <- filter(site_wise_product_details, site == event$id) %>% select(product)
      if(nrow(products_at_site) == 0){
        return(NULL)
      }
      
      products <- unique(products_at_site$product)
      
      radioButtons("products_at_site", label = paste("Products at ", event$id , " site:", sep = ""), choices = products, selected = products[1])
    
  })
  
  output$`monthwise-production` <- renderPlot({

    leafletProxy("map") %>% clearPopups()
    event <- input$map_marker_click
    
    if (is.null(event))
      return(NULL)
    
    selected_product <- input$products_at_site
    
    if (is.null(selected_product))
      return(NULL)
    
    yearly_product_data <- filter(site_wise_product_details, site == event$id, product == selected_product) %>% select(-site, -product)
    
    if(nrow(yearly_product_data) == 0)
      return(NULL)
    
    yearly_product_data <- yearly_product_data[1,]
    
    gathered_product_data <- gather(yearly_product_data, month, production)
    
    shinyjs::removeClass("main_map", "map_init")
    shinyjs::addClass("main_map","map_collapse")
    
    ggplot(data=gathered_product_data, aes(x=month, y=production, group=1)) +
      geom_line(size = 1, colour = "#0071d1")+
      geom_point(size = 3, colour="#31708f")+ scale_x_discrete(limits=c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")) + 
      expand_limits( y = c(250, 10000)) + 
      theme(panel.background = element_rect(fill = '#d9edf7', colour = '#337ab7'), text = element_text(colour = "#143c50", size = 15)) + 
      ggtitle(paste("Production Analysis of", selected_product, "at", event$id, sep = " ")) + 
      theme(plot.title = element_text(colour = "#172b3b", size = 20, hjust = 0.5))

  })
  
})