# Load necessary packages
library(rvest)
library(tidyverse)
library(mongolite)

# Define MongoDB connection details
collection <- "Scraping_mds"
db <- "ProjectUAS"
url <- "mongodb+srv://smutiah842:Aretha4488@cluster0.mur8qem.mongodb.net/" 
atlas_conn <- mongo(collection=collection, db=db, url=url)

message('Loading Packages')
library(rvest)
library(tidyverse)
library(mongolite)

message('Scraping Data')
url <- "https://www.scimagojr.com/journalrank.php?area=1700"
page <- read_html(url)

# Menyesuaikan selector XPath atau CSS sesuai struktur halaman web yang dituju
rank <- page %>% html_nodes(css = 'td:nth-child(1)') %>% html_text(trim = TRUE)
journal <- page %>% html_nodes(css = 'td:nth-child(2)') %>% html_text(trim = TRUE)
h_index <- page %>% html_nodes(css = 'td:nth-child(5)') %>% html_text(trim = TRUE)
sjr <- page %>% html_nodes(css = 'td:nth-child(6)') %>% html_text(trim = TRUE)
total_docs_2022 <- page %>% html_nodes(css = 'td:nth-child(7)') %>% html_text(trim = TRUE)
total_docs_3years <- page %>% html_nodes(css = 'td:nth-child(8)') %>% html_text(trim = TRUE)
total_refs <- page %>% html_nodes(css = 'td:nth-child(9)') %>% html_text(trim = TRUE)
country <- page %>% html_nodes(css = 'td:nth-child(10)') %>% html_text(trim = TRUE)

# Menggabungkan data menjadi satu dataframe
data <- data.frame(
  time_scraped = Sys.time(),
  rank = rank[1:10],
  journal = journal[1:10],
  h_index = h_index[1:10],
  sjr = sjr[1:10],
  total_docs_2022 = total_docs_2022[1:10],
  total_docs_3years = total_docs_3years[1:10],
  total_refs = total_refs[1:10],
  country = country[1:10],
  stringsAsFactors = FALSE
)

# MONGODB
message('Input Data to MongoDB Atlas')
atlas_conn <- mongo(
  collection = Sys.getenv("ATLAS_COLLECTION"),
  db         = Sys.getenv("ATLAS_DB"),
  url        = Sys.getenv("ATLAS_URL")
)

atlas_conn$insert(data)
rm(atlas_conn)

message('Data successfully scraped and inserted into MongoDB Atlas')
