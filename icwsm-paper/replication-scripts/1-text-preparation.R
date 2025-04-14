
## 1. Importing Texts ####

### 1.1 PGA Texts ####

# Function to import PGA texts
import_PGA_texts <- function(data_dir, pattern = "Community Guidelines\\.md$") {
  # List all directories
  platforms <- list.dirs(data_dir, full.names = TRUE)
  
  # Initialize an empty list to store text data
  text_data <- list()
  
  # Loop through each platform directory
  for (platform in platforms) {
    files <- list.files(platform, full.names = TRUE)
    guidelines_files <- files[grep(pattern, files)]
    
    for (file in guidelines_files) {
      text <- readtext(file, encoding = "UTF-8")
      text_data[[file]] <- text
    }
  }
  
  # Combine into a data frame
  text_df <- do.call(rbind, text_data)
  
  # Extract platform names for row names
  current_row_names <- rownames(text_df)
  extract_platform_name <- function(file_path) {
    path_components <- unlist(strsplit(file_path, "/"))
    platform_name <- path_components[length(path_components) - 1]
    return(platform_name)
  }
  
  new_row_names <- sapply(current_row_names, extract_platform_name)
  rownames(text_df) <- new_row_names
  
  # Convert row names to a column
  text_df$platform <- rownames(text_df)
  rownames(text_df) <- NULL
  
  # Remove unnecessary columns
  text_df$doc_id <- NULL
  colnames(text_df) <- c('text', 'platform')
  
  return(text_df)
}

# Setting directory for PGA texts
data_dir <- "../../data/pga-versions"

### 1.2 COMPARE Texts ####

# Function to import COMPARE texts
import_COMPARE_texts <- function(data_dir2) { 
  platform_folders <- list.dirs(data_dir2, full.names = FALSE, recursive = FALSE)
  data_frames_list <- list()
  
  for (platform_folder in platform_folders) {
    if (platform_folder != "" ) { 
      platform_name <- platform_folder
      
      txt_files_en <- list.files(file.path(data_dir2, platform_folder), pattern = "_en\\.md$", full.names = TRUE)
      txt_files_all_md <- list.files(file.path(data_dir2, platform_folder), pattern = "\\.md$", full.names = TRUE)
      txt_files_markdown <- txt_files_all_md[!grepl("_\\w{2}\\.md$", txt_files_all_md)]
      
      txt_files <- if (length(txt_files_en) > 0) txt_files_en else txt_files_markdown
      
      if (length(txt_files) > 0) {
        platform_texts <- readtext(txt_files)
        platform_texts$Name <- tools::file_path_sans_ext(basename(txt_files))
        platform_texts <- platform_texts[, c("Name", "text")]
        data_frames_list[[platform_name]] <- platform_texts
      } else {
        message("No relevant files found in ", platform_folder, ", skipping this folder.")
      }
    }
  }
  
  text_df <- do.call(rbind, data_frames_list)
  
  # Convert row names to a column
  text_df$platform <- rownames(text_df)
  rownames(text_df) <- NULL
  
  # Remove unnecessary columns
  text_df$Name <- NULL
  
  return(text_df)
}

# Setting directory for COMPARE texts
data_dir2 <- "../../data/community-guidelines"


### 1.3 Combining both ####

# Function to combine both 
combine_text <- function(text_df1, text_df2, exclude_platforms) {
  text_df1 <- text_df1 %>% filter(!platform %in% exclude_platforms)
  text_df <- rbind(text_df1, text_df2)
  return(text_df)
}

# Main function to orchestrate the workflow
process_text_files <- function(data_dir, data_dir2, exclude_platforms) { 
  text_df1 <- import_PGA_texts(data_dir)
  text_df2 <- import_COMPARE_texts(data_dir2)
  text_df <- combine_text(text_df1, text_df2, exclude_platforms)
  return(text_df)
}

# Excluding platforms:
# Parler & Spotify are not part of COMPARE, Twitter is replaced by X, 
# WeChat includes the English versions but we scraped the Chinese version, Instagram also uses Facebook's guidelines
exclude_platforms <- c('Parler', 'Spotify', 'Twitter', 'WeChat', 'Instagram')

# Executing functions
text_df <- process_text_files(data_dir, data_dir2, exclude_platforms)

# Removing unnecessary files
rm(data_dir,data_dir2,exclude_platforms,import_COMPARE_texts,combine_text,process_text_files)

## 2. Text Cleaning ####

### 2.1 Main text-cleaning function ####
text_cleaning_markdown <-function(md) {
  # Markdown parser
  text<- markdown_text(md,width=100000)
  
  # Replaces strange white spaces
  text <-gsub("[\u00a0 ]+\n", "\n", text)
  text <-gsub("\u200D","",text)
  
  # Removes -
  text <-gsub("  - "," ",text)
  
  # Replace with \n with dot if not precedented by .?!\n
  text <-gsub("(?<![.?!\n])\n+", ". ", text, perl = T)
  text <-gsub("\n+", " ", text,perl = T)
  
  # Remove two or more whitespaces
  text <-gsub("\\s{2,}"," ",text)
  # Removing YouTube crisis Phone Numbers: 
  text <-gsub("\\|\\s\\|.+\\|\\.", ".", text)
  
  # Google Translation signs (Aparat & Ninisite) 
  text <-gsub("#39;", "'",text)
  
  # Remaining links (8kun)
  text <-gsub("https?://\\S+", "", text)
  
  # Remove special dot ·
  text <-gsub("·", "", text)
  
  # Dxy: strange numbers (①)
  text <- gsub("① *","1\\. ", text) 
  text <- gsub("② *" ,"2\\. ", text) 
  text <- gsub("③ *" ,"3\\. ", text) 
  text <- gsub("④ *" ,"4\\. ", text) 
  text <- gsub("⑤ *" ,"5\\. ", text) 
  
  # Kakao: more strange numbers
  text <- gsub("⑥ *" ,"6\\. ", text) 
  text <- gsub("⑦ *" ,"7\\. ", text) 
  text <- gsub("⑧ *","8\\. ", text) 
  text <- gsub("⑨ *" ,"9\\. ", text) 
  
  ## Numbering:
  #(1) to  1. (DXY)
  text <- gsub("\\((\\d+)\\) *", "\\1. ", text)
  text <- gsub("(\\d+)\\) *", "\\1. ", text)
  
  # 1. 1. (Bluesky)
  text <- gsub("(\\d+\\.) (\\d+\\.) * ", "\\1\\2 ", text)
  
  # 4.1. 1. (Nmn Club )
  text <- gsub("(\\d+\\.)(\\d+\\.) (\\d+\\.) *", "\\1\\2\\3 ", text)
  
  # Add dot before numbering to start a new sentence  
  text <- gsub("([^.?!*]) (\\d+\\.\\d?\\.?\\d?\\.?\\d?\\.?\\d?\\.?\\d?\\.?\\d?\\.?)", "\\1. \\2.", text)
  
  # Roman Numbers 
  text <- gsub("(.) (\\S?I{1,3}\\S?\\.) *", "\\1. \\2 ", text)
  # a. b.
  text <- gsub("(.) ([a-z]\\.) *", "\\1. \\2 ", text)
  # (i) to I.
  text <- gsub("(.) \\(([a-z]+)\\) *", "\\1. \\2. ", text)
  # d) to . d. 
  text <- gsub("(.) ([a-z]{1,2})\\)", "\\1. \\2.", text)
  
  # Punctuation
  text <-gsub("\\.{2,}", "\\.",text)
  text <-gsub("\\.\\s+\\.", "\\.",text)
  text <- gsub("\\:\\.",": ", text)
  text <-gsub("\\:\\s+\\.", "\\: ",text)
  text <- gsub("\\?\\.", "?", text)
  text <- gsub("\\!\\.", "!", text)
  text <- gsub("●","",text)
  
  #Replace semicolon with dot
  text <- gsub("\\;","\\.", text)
  
  # Removing double dots and . .
  text <- gsub( "\\.\\s+\\.",".",text)
  text <- gsub( "\\.\\.",".",text)
  
  return(text)
}


### 2.2 Function to remove remaining markdown signs ####
text_cleaning_remaining_markdown <-function(text) { 
  text <-gsub("-{2,}", "",text)
  text <-gsub("\\*+"," ",text)
  text <-gsub("\\#+"," ",text)
  text <- gsub("=+","",text)
  text <- gsub("\\.\\s+\\.",".",text)
  text <-gsub ("\\s{2,}","",text) 
  return(text)
}

### 3. Applying cleaning functions ####

# General text cleaning function
text_df$text <- sapply(text_df$text, text_cleaning_markdown)

# Remove left-over markdown signs
text_df$text <- sapply(text_df$text, text_cleaning_remaining_markdown)



