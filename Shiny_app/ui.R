# Load libraries
library(shiny)
library(ggplot2)
library(sf)
library(leaflet)
library(stringr)
library(tidyverse)
library(shinythemes)
library(shinydashboard)
library(htmltools)
library(reshape2)
library(scales)
library(RColorBrewer)
library(ggrepel)
library(shinyWidgets)

gemeenten <- readRDS("../Data/gemeenten.rds")


ui <- dashboardPage(
  dashboardHeader(title = "Buurtvergelijker"),
  dashboardSidebar(
    sidebarMenu(


      menuItem("Voorzieningen", tabName = "Voorzieningen", icon = icon("building", class = "fa-solid fa-building", lib = "font-awesome")),
      menuItem("Gezondheid", tabName = "Gezondheid", icon = icon("briefcase-medical", class = "fa-solid fa-briefcase-medical", lib = "font-awesome")),
      menuItem("Verkeersongevallen", tabName = "Verkeersongevallen", icon = icon("car-side", class = "fa-solid fa-car-side", lib = "font-awesome")),
      menuItem("Criminaliteit", tabName = "Criminaliteit", icon = icon("handcuffs", class = "fa-solid fa-handcuffs", lib = "font-awesome")))

  ), # Dashboard sidebar
  dashboardBody(tags$head(tags$style(HTML('.box{box-shadow: none;border-style: none;}.content-wrapper { overflow: auto; }.leaflet-top, .leaflet-bottom {
    z-index: unset !important;
  }'))),
                tabItems(
                  ### Facilities ###
                  
                  tabItem(
                    tabName = "Voorzieningen",

                    h2("Dashboard nabijheid voorzieningen op gemeente-, wijk- of buurtniveau"),


                    fluidRow(
                      column(width = 3,
                             box(title = "Uitleg app", width = NULL, status = "primary", solidHeader = T, collapsible = T, collapsed = T,
                                 "In deze app kunt u informatie vinden over de afstand tot voorzieningen in een gebied.", br(),
                                 br(),
                                 "Als eerste moet de box “Kies een niveau” worden ingevuld. Hier kan een niveau geselecteerd worden,
                                 een gebied, en met welke andere gebieden u wilt vergelijken. Weet u niet in welke wijk of buurt u woont? 
                                 Dan kunt u eerst nog uw postcode invullen bij “Postcode zoeken?”. 
                                 Als u tevreden bent met uw keuze, druk dan op “Zoeken”.", br(),
                                 br(),
                                 "Hierna verschijnt een box met informatie over het gekozen gebied. Ook ziet u een kaart met uw gekozen 
                                 gebied (blauwe pointer) en de andere gebieden waarmee wordt vergeleken. 
                                 Als laatste ziet u nog een lijst met de 5 gebieden die het meest op uw gebied lijken. 
                                 Dit is berekend op basis van de afstand tot voorzieningen en het aantal voorzieningen binnen een bepaalde afstand. 
                                 Deze gebieden zijn in de kaart te zien met de rode pointers.", br(),
                                 br(),
                                 "Vervolgens kunt u bij “Thema” een thema en subthema kiezen. 
                                 Dan ziet u een kaart met de afstand tot de gekozen voorziening voor het gekozen gebied (blauwe pointer) 
                                 en voor alle gebieden waarmee wordt vergeleken. Ook is opnieuw een lijst te zien met de 5 gebieden 
                                 die het meest op uw gebied lijken. Dit keer alleen op basis van de voorzieningen in het gekozen thema. 
                                 Deze gebieden zijn in de kaart te zien met de groene pointers. Als laatste ziet u nog een staafdiagram
                                 met hoeveel voorzieningen er binnen een bepaalde afstand zitten. "), # Uitleg app
                             box(title = "Postcode zoeken?", width = NULL, status = "primary", solidHeader = T, collapsible = T, collapsed = T,
                                 textInput("postcode", "Weet u niet uw precieze gemeente, wijk of buurt? Vul dan hier uw postcode in:"),
                                 textOutput("postcode_info")), # Box postcode zoeken
                             box(title = "Kies een niveau", width = NULL, status = "primary", solidHeader = T,
                                 "Kies het gewenste niveau, gebied en waar u mee wilt vergelijken en druk op 'zoeken' om door te gaan.",

                                 selectInput("niveau", "Niveau:", c("Gemeenten" = "Gemeenten",
                                                                    "Wijken" = "Wijken",
                                                                    "Buurten" = "Buurten")), # Select input niveau
                                 conditionalPanel(
                                   condition = "input.niveau == 'Gemeenten'",
                                   selectInput("gemeente1", "Gemeente:", choices = unique(gemeenten$GM_NAAM)), # Select input gemeente1
                                   selectInput("vergelijkbaar1", "Vergelijken met:", c("Alle gebieden in Nederland" = "Nederland", 
                                                                                       "Gebieden met dezelfde stedelijkheid" = "Stedelijkheidsniveau",
                                                                                       "Gebieden met ongeveer hetzelfde inkomen" = "Inkomensniveau")) # Select input vergelijkbaar1

                                 ), # Conditional panel 1 gemeenten
                                 conditionalPanel(
                                   condition = "input.niveau == 'Wijken'",
                                   selectInput("gemeente2", "Gemeente:", choices = unique(gemeenten$GM_NAAM)), # Select input gemeente2
                                   selectInput("wijken2", "Wijk:", choices = NULL), # Select input wijken2,
                                   selectInput("vergelijkbaar2", "Vergelijken met:", c("Alle gebieden in Nederland" = "Nederland", 
                                                                                       "Gebieden met dezelfde stedelijkheid" = "Stedelijkheidsniveau",
                                                                                       "Gebieden met ongeveer hetzelfde inkomen" = "Inkomensniveau")) # Select input vergelijkbaar 2

                                 ), # Conditional panel 2 wijken
                                 conditionalPanel(
                                   condition = "input.niveau == 'Buurten'",
                                   selectInput("gemeente3", "Gemeente:", choices = unique(gemeenten$GM_NAAM)), # Select input gemeente3
                                   selectInput("wijken3", "Wijk:", choices = NULL), # Select input wijken3
                                   selectInput("buurten3", "Buurt:", choices = NULL), # Select input buurten3
                                   selectInput("vergelijkbaar3", "Vergelijken met:", c("Alle gebieden in Nederland" = "Nederland", 
                                                                                       "Gebieden met dezelfde stedelijkheid" = "Stedelijkheidsniveau")) # Select input vergelijkbaar3
                                 ), # Conditional panel 3 buurten
                                 actionButton("action", "Zoeken")
                             ), # Box selecteer niveau
                      ), # Column
                      uiOutput("info_box"), # Box informatie
                      uiOutput("kaart_box"), # Box geselecteerde plek
                      uiOutput("top5_all") # Box top 5 algemeen

                    ), # Fluid row 1 postcode, thema, algemene top 5, niveau, geselecteerde plek
                    fluidRow(
                      column(width = 2,
                             box(title = "Thema", width = NULL, status = "primary", solidHeader = T,
                                 selectInput("thema", "Thema:", c("Gezondheid en welzijn", "Detailhandel", "Horeca", 
                                                                  "Kinderopvang", "Onderwijs", "Verkeer en vervoer", 
                                                                  "Vrije tijd en cultuur")), 
                                 selectInput("subthema", "Subthema:", choices = NULL),
                                 actionButton("action_theme", "Zoeken")), # Box thema

                             uiOutput("top5"), # Box top 5 thema
                      ),
                      uiOutput("kaartNL"), # Box kaart
                      uiOutput("box_staafdiagram"),
                    ), # Fluid row 2 histogram, kaart, thema top 5
                    "Bron data: Kerncijfers wijken en buurten 2020 CBS"
                  ), # Tab item voorzieningen
                  

                  ### Health ###   
                  
                  tabItem(tabName = "Gezondheid",
                          h2("Dashboard gezondheid op  gemeente-, wijk-, of buurtniveau"),
                          fluidRow(
                            column(width = 3,
                                   box(title = "Uitleg app", width = NULL, status = "primary", solidHeader = T, collapsible = T, collapsed = T,
                                       "In deze app kunt u informatie vinden over de gezondheid in een gebied. Dit is gebaseerd op data van het RIVM 
                                       (te vinden op: statline.rivm.nl/RIVM/nl/dataset/50090NED). 
                                       Deze data zijn schattingen gebaseerd op vragenlijsten die door meer dan 500.000 mensen zijn ingevuld. 
                                       Voor 95% zekerheidsintervallen kunt u de originele data bekijken.", br(),
                                       br(),
                                       strong("Uitleg werking app:"),br(),
                                       "Als eerste moet de box “Niveau en gebied selecteren” worden ingevuld. Hier kan een niveau geselecteerd worden,
                                        een gebied, en met welke andere gebieden u wilt vergelijken. 
                                        Als u tevreden bent met uw keuze, druk dan op “Zoeken”.", br(),
                                       br(),
                                       "Hierna verschijnt een box met informatie over het gekozen gebied. Daarnaast is de leeftijdsopbouw van het 
                                       gebied te zien. Ook ziet u een kaart met uw gekozen gebied (blauwe pointer) en de andere gebieden 
                                       waarmee wordt vergeleken.", br(),
                                       br(),
                                       "Vervolgens kunt u bij “Kies een thema” een thema en subthema kiezen. 
                                        Dan ziet u verschillende visualisaties voor het gekozen subthema. Voor een deel van de visualisaties kunt
                                       u nog kiezen voor welke leeftijdsgroep u de gezondheid wilt zien. "), # Uitleg app
                                   box(title="Niveau en gebied selecteren", width = NULL, status = 'primary', solidHeader = T,
                                       "Selecteer het gewenste niveau, gebied en vergelijkbaarheidsniveau en druk op 'zoeken' om door te gaan.", br(),
                                       br(),
                                       selectInput("niveau_gez", "Niveau:", c("Gemeenten" = "Gemeenten",
                                                                              "Wijken" = "Wijken",
                                                                              "Buurten" = "Buurten")),
                                       conditionalPanel(
                                         condition = "input.niveau_gez == 'Gemeenten'",
                                         selectInput("gemeente1_gez", "Gemeente:", choices = unique(gemeenten$GM_NAAM)), # Select input gemeente1
                                         selectInput("vergelijkbaar1_gez", "Vergelijken met:", c("Gebieden met dezelfde leeftijdsopbouw" = "age_distribution",
                                                                                               "Alle gebieden in Nederland" = "Nederland", 
                                                                                               "Gebieden met hetzelfde stedelijkheidsniveau" = "Stedelijkheidsniveau",
                                                                                               "Gebieden met hetzelfde inkomensniveau" = "Inkomensniveau")) # Select input vergelijkbaar1
                                       ), #conditionalpanel 1
                                       conditionalPanel(
                                         condition = "input.niveau_gez == 'Wijken'",
                                         selectInput("gemeente2_gez", "Gemeente:", choices = unique(gemeenten$GM_NAAM)), # Select input gemeente2
                                         selectInput("wijken2_gez", "Wijk:", choices = NULL), # Select input wijken2,
                                         selectInput("vergelijkbaar2_gez", "Vergelijken met:", c("Gebieden met dezelfde leeftijdsopbouw" = "age_distribution",
                                                                                               "Alle gebieden in Nederland" = "Nederland", 
                                                                                               "Gebieden met hetzelfde stedelijkheidsniveau" = "Stedelijkheidsniveau",
                                                                                               "Gebieden met hetzelfde inkomensniveau" = "Inkomensniveau")), # Select input vergelijkbaar 2
                                       ), # Conditional panel 2
                                       conditionalPanel(
                                         condition = "input.niveau_gez == 'Buurten'",
                                         selectInput("gemeente3_gez", "Gemeente:", choices = unique(gemeenten$GM_NAAM)), # Select input gemeente3
                                         selectInput("wijken3_gez", "Wijk:", choices = NULL), # Select input wijken3
                                         selectInput("buurten3_gez", "Buurt:", choices = NULL), # Select input buurten3
                                         selectInput("vergelijkbaar3_gez", "Vergelijken met:", c("Gebieden met dezelfde leeftijdsopbouw" = "age_distribution",
                                                                                               "Alle gebieden in Nederland" = "Nederland", 
                                                                                               "Gebieden met hetzelfde stedelijkheidsniveau" = "Stedelijkheidsniveau")) # Select input vergelijkbaar3
                                       ), # Conditional panel 3 buurten
                                       actionButton("action_gez", "Zoeken")
                                   ) #box voor niveau 
                            ), #column 
                            uiOutput("info_box_gez"), # Box informatie
                            uiOutput("age_box_gez"), # Box age distribution
                            uiOutput("kaart_box_gez"), # Box geselecteerde plek
                            
                          ), #fluidrow gezondheid input
                          br(),
                          br(),
                          fluidRow(
                                   box(title = "Kies een thema", width = 3, status = "primary", solidHeader = T,
                                       "Selecteer het gewenste thema en subthema en druk op 'zoeken' om door te gaan.", br(),
                                       br(),
                                       selectInput("thema_gez", "Thema:", c("Gezondheid en beperkingen", "Leefstijl", "Participatie en omgeving") ), 
                                       selectInput("subthema_gez", "Subthema:", choices = NULL),
                                       actionButton("action_thema_gez", "Zoeken")
                                       ),
                            
                                  uiOutput("plots")
                            
                          ), #fluidrow gezondheid plots
                      "Bron data: Gezondheid per wijk en buurt; 2012/2016/2020 (indeling 2020) RIVM"    
                  ), # tab item gezondheidszorg
                  
                  
                  ### TRAFFIC INCIDENTS ###

                  tabItem(tabName = "Verkeersongevallen",
                          h2("Verkeersongevallen in gemeenten, wijken en buurten van Nederland"),
                          h3("Algemeen overzicht van verkeersongevallen"),
                          fluidRow(
                            column(width = 3,
                                   box(title = "Selecteer het gebied van interesse", width = NULL, status = "primary", solidHeader = T,
                                       selectInput("niveau_incidents", "Niveau:", c("Gemeenten" = "Gemeenten",
                                                                           "Wijken" = "Wijken",
                                                                           "Buurten" = "Buurten")), # Select input niveau_incidents
                                       conditionalPanel(
                                         condition = "input.niveau_incidents == 'Gemeenten'",
                                         selectInput("gemeente_1_incidents", "Gemeente:", choices = unique(gemeenten$GM_NAAM)) # Select input gemeente_1
                                       ), # Conditional panel 1 gemeenten
                                       conditionalPanel(
                                         condition = "input.niveau_incidents == 'Wijken'",
                                         selectInput("gemeente_2_incidents", "Gemeente:", choices = unique(gemeenten$GM_NAAM)), # Select input gemeente_2
                                         selectInput("wijken_2_incidents", "Wijk:", choices = NULL) # Select input wijken_2
                                       ), # Conditional panel 2 wijken
                                       conditionalPanel(
                                         condition = "input.niveau_incidents == 'Buurten'",
                                         selectInput("gemeente_3_incidents", "Gemeente:", choices = unique(gemeenten$GM_NAAM)), # Select input gemeente_3
                                         selectInput("wijken_3_incidents", "Wijk:", choices = NULL), # Select input wijken_3
                                         selectInput("buurten_3_incidents", "Buurt:", choices = NULL) # Select input buurten_3
                                       ), # Conditional panel 3 buurten
                                       selectInput("jaar", "Jaar:", c("2020" = "2020",
                                                                       "2019" = "2019",
                                                                       "2018" = "2018"
                                                                       )), # Select input jaar
                                       selectInput("subthema_incidents", "Subthema:", c("Afloop" = "AP3_OMS",
                                                                               "Weersgesteldheid" = "WGD_CODE_1",
                                                                               "Aard" = "AOL_OMS",
                                                                               "Objecttype" = "OTE_OMS",
                                                                               "Wegsituatie" = "WSE_OMS",
                                                                               "Maximum snelheid" = "MAXSNELHD",
                                                                               "Aantal betrokken partijen" = "ANTL_PTJ")),
                                   actionButton("action_incidents", "Zoeken")
                                   ), # Box input
                                   box(title = "Uitleg van subthema", width = NULL, status = "primary", solidHeader = T,
                                       textOutput("explanation_incidents"))
                            ), # Column 1
                            column(width = 5,
                                   box(title = "Algemene trend", width = NULL, status = "danger", solidHeader = T,
                                       "De lijn in de grafiek geeft aan hoeveel ongelukken er hebben plaatsgevonden in het geselecteerde gebied in verschillende jaren.",
                                       shinycssloaders::withSpinner(plotOutput("general_trend"))) # Box algemene trend
                            ), # Column 2
                            column(width = 4,
                                   valueBoxOutput("number_incidents", width = NULL),
                                   valueBoxOutput("stedelijkheid_num", width = NULL)
                            ) # Column 3
                          ), # fluid row algemene trend en aantal
                          h3("Inzicht in subthema in uw buurt"),
                          uiOutput("subtheme_row"),
                          h3("Vergelijk het geselecteerde gebied met andere, vergelijkbare gebieden"),
                          fluidRow(
                            column(width = 4,
                                   box(title = "Top-5 incidenten in vergelijkbare gebieden", width = NULL, status = "success", solidHeader = T,
                                       HTML("In deze tabel wordt de top-5 van gebieden met de meeste incidenten weergegeven. Alleen gebieden met hetzelfde stedelijkheidsniveau worden vergeleken met het geselecteerde gebied <br>
                                            Staat het door u geselecteerde gebied niet in de top-5? Dan ziet u onderaan de tabel op welke rank het geselecteerde gebied staat."),
                                       tableOutput("count_incidents")) # Box top 5
                                   ), # Column top 5
                            column(width = 6,
                                   box(title = "Vergelijking met andere gebieden", width = NULL, status = "success", solidHeader = T,
                                       HTML("In deze grafiek wordt getoond bij hoeveel gebieden een bepaald aantal ongelukken plaatsvindt. <br>
                                            De blauwe lijn is het door u geselecteerde gebied. De groene lijn is een gemiddelde van vergelijkbare gebieden. <br>
                                            Als de blauwe lijn links van de groene lijn staat, dan doet het geselecteerde gebied het goed ten opzichte van het gemiddelde van gebieden met hetzelfde stedelijkheidsniveau."),
                                       plotOutput("histogram_incidents")) # Box grafieken of diagram
                            ) # Column vergelijking buurt
                          ), # Fluid row 3 vergelijkbaarheid
                          "Bron data: Bestand geRegistreerde Ongevallen in Nederland, Rijkswaterstaat (2011-2020)"
                  ), # Tab Item verkeersveiligheid
                  
                  
                  #### START CRIMINALITEIT
                  
                  tabItem(tabName = "Criminaliteit",
                          h2("Criminaliteit: Dashboard misdrijven op gemeente-, wijk-, en buurtniveau"),
                          fluidRow(
                            column(width = 3, 
                                   box(title = "Selecteer niveau", status = "primary", solidHeader = T, width = NULL,
                                       selectInput("niveau_crime", "Niveau:", choices = c("Gemeenten", "Wijken", "Buurten")),
                                       conditionalPanel(
                                         condition = "input.niveau_crime == 'Gemeenten'",
                                         selectInput("gemeente_crime1", "Gemeente:", choices = unique(gemeenten$GM_NAAM)),
                                         selectInput("vergelijkbaar_crime1", "Vergelijken met:", c("Alle gebieden in Nederland" = "Nederland", 
                                                                                                   "Gebieden met hetzelfde stedelijkheidsniveau" = "Stedelijkheidsniveau",
                                                                                                   "Gebieden met hetzelfde inkomensniveau" = "Inkomensniveau"))),
                                       conditionalPanel(
                                         condition = "input.niveau_crime == 'Wijken'", 
                                         selectInput("gemeente_crime2", "Gemeente:", choices = unique(gemeenten$GM_NAAM)),
                                         selectInput("wijken_crime2", "Wijk:", choices = NULL), 
                                         selectInput("vergelijkbaar_crime2", "Vergelijken met:", c("Alle gebieden in Nederland" = "Nederland", 
                                                                                                   "Gebieden met hetzelfde stedelijkheidsniveau" = "Stedelijkheidsniveau",
                                                                                                   "Gebieden met hetzelfde inkomensniveau" = "Inkomensniveau"))),
                                       conditionalPanel(
                                         condition = "input.niveau_crime == 'Buurten'", 
                                         selectInput("gemeente_crime3", "Gemeente:", choices = unique(gemeenten$GM_NAAM)), 
                                         selectInput("wijken_crime3", "Wijk:", choices = NULL),
                                         selectInput("buurten_crime3", "Buurt:", choices = NULL), 
                                         selectInput("vergelijkbaar_crime3", "Vergelijken met:", c("Alle gebieden in Nederland" = "Nederland", 
                                                                                                   "Gebieden met hetzelfde stedelijkheidsniveau" = "Stedelijkheidsniveau"))),
                                       
                                       selectInput("aantal_crime", "Aantallen:", choices = c("Aantal misdrijven", "Aantallen per 1000 inwoners")), 
                                       actionButton("action_crime", "Zoeken"))), 
                            column(width = 6, 
                                   box(title = "Grafiek met misdrijven over tijd", status = "warning", solidHeader = T, width = NULL,
                                       shinycssloaders::withSpinner(plotOutput("crime_plot")))), 
                            column(width = 3, 
                                   box(title = "Uitleg geselecteerde misdaad", status = "warning", solidHeader = T, width = NULL,
                                       textOutput("info_crime")))
                          ),
                          fluidRow(
                            column(width = 3, 
                                   box(title = "Selecteer thema", status = "primary", solidHeader = T, width= NULL,
                                       selectInput("thema_crime", "Thema misdrijf", choices = c("Totaal misdrijven",
                                                                                                "Vermogensdelicten",
                                                                                                "Gewelds- en seksuele misdrijven", 
                                                                                                "Vernielingen en misdrijven tegen openbare orde en gezag", 
                                                                                                "Verkeersmisdrijven", 
                                                                                                "Misdrijven omgeving en milieu", 
                                                                                                "Overige misdrijven")),
                                       selectInput("soort_crime", "Soort misdrijf:", choices = NULL), 
                                       selectInput("jaar_crime", "Jaar:", choices = c("2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019", "2020", "2021")))), 
                            column(width = 6, 
                                   box(title = "Kaart met misdrijven", status = "warning", solidHeader = T, width = NULL,
                                       shinycssloaders::withSpinner(leafletOutput("crime_map")))),
                            column(width =3, 
                                   uiOutput("top5_crime")
                                   #box(title = "Top 5 criminaliteit", background = "red", width = NULL,
                                   #"Top 5 met de meeste geselecteerde criminaliteit",
                                   #"Hier komt de algemene top 5 zonder geselecteerd thema",
                                   #tableOutput('top5_crime2'))
                                   
                            )
                          )
                  ) # Tab item criminaliteit
                  
                ) # TabItems
  ) # Dashboard body
) # Dashboard page



