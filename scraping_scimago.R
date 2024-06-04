# Define MongoDB connection details
collection <- "Scraping_mds"
db <- "ProjectUAS"
url <- "mongodb+srv://smutiah842:Aretha4488@cluster0.mur8qem.mongodb.net/" 
atlas_conn <- mongo(collection=collection, db=db, url=url)

library(rvest)
library(httr)
library(mongolite)

# Fungsi untuk membaca nomor halaman terakhir dari file
read_last_page <- function() {
  if (file.exists("last_page.txt")) {
    return(as.integer(readLines("last_page.txt")))
  } else {
    return(1)
  }
}

# Fungsi untuk menyimpan nomor halaman terakhir ke file
write_last_page <- function(page_number) {
  writeLines(as.character(page_number), "last_page.txt")
}

# Fungsi untuk melakukan scraping
scrape_scimago <- function(url) {
  page <- GET(url)
  if (status_code(page) == 200) {
    page_content <- read_html("https://www.scimagojr.com/journalrank.php?area=1700")
    
    rank <- page_content %>% html_nodes(css = 'td:nth-child(1)') %>% html_text(trim = TRUE)
    journal <- page_content %>% html_nodes(css = 'td:nth-child(2)') %>% html_text(trim = TRUE)
    h_index <- page_content %>% html_nodes(css = 'td:nth-child(5)') %>% html_text(trim = TRUE)
    sjr <- page_content %>% html_nodes(css = 'td:nth-child(6)') %>% html_text(trim = TRUE)
    total_docs_2022 <- page_content %>% html_nodes(css = 'td:nth-child(7)') %>% html_text(trim = TRUE)
    total_docs_3years <- page_content %>% html_nodes(css = 'td:nth-child(8)') %>% html_text(trim = TRUE)
    total_refs <- page_content %>% html_nodes(css = 'td:nth-child(9)') %>% html_text(trim = TRUE)
    country <- page_content %>% html_nodes(css = 'td:nth-child(10)') %>% html_text(trim = TRUE)
    
    length_check <- min(length(rank), length(journal), length(h_index), length(sjr), length(total_docs_2022), length(total_docs_3years), length(total_refs), length(country))
    
    if (length_check > 0) {
      data <- data.frame(
        time_scraped = Sys.time(),
        rank = head(rank, length_check),
        journal = head(journal, length_check),
        h_index = head(h_index, length_check),
        sjr = head(sjr, length_check),
        total_docs_2022 = head(total_docs_2022, length_check),
        total_docs_3years = head(total_docs_3years, length_check),
        total_refs = head(total_refs, length_check),
        country = head(country, length_check),
        stringsAsFactors = FALSE
      )
      return(data)
    } else {
      print("Tidak ada data yang ditemukan di halaman ini.")
      return(NULL)
    }
  } else {
    print("Gagal mengambil halaman")
    return(NULL)
  }
}

# Membaca nomor halaman terakhir
last_page <- read_last_page()

# URL halaman Scimago
url <- paste0("https://www.scimagojr.com/journalrank.php?category=1700&page=", last_page)

# Memanggil fungsi untuk melakukan scraping
scimago_data <- scrape_scimago(url)
if (!is.null(scimago_data)) {
  print(scimago_data)
  
  # MONGODB
  message('Input Data to MongoDB Atlas')
  
  # Membuat koneksi ke MongoDB Atlas
  atlas_conn <- mongo(
    collection = Sys.getenv("ATLAS_COLLECTION"),
    db = Sys.getenv("ATLAS_DB"),
    url = Sys.getenv("ATLAS_URL")
  )
  
  # Memasukkan data ke MongoDB Atlas
  atlas_conn$insert(scimago_data)
  
  # Menutup koneksi setelah selesai
  rm(atlas_conn)
  
  # Memperbarui nomor halaman terakhir
  write_last_page(last_page + 1)
} else {
  print("Tidak ada data untuk dimasukkan ke MongoDB.")
}

# Membuang variabel yang tidak diperlukan
rm(url, scrape_scimago, last_page, scimago_data, read_last_page, write_last_page)
