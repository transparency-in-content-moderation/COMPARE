##########################################################################################################################
###### This script was used to generate translations of the non-English community guidelines in the COMPARE dataset ######
################### (https://github.com/transparency-in-content-moderation/COMPARE) ######################################
##########################################################################################################################

import requests
import os
import re
from google.cloud import translate_v2 as translate
from google.oauth2 import service_account 

# Function to translate text using the DeepL API
# Takes the input text and target language as arguments
# Sends a POST request to the DeepL API and returns the translated text
# Handles errors by printing the status code and error message

def translate_text_deepl(text, target_lang):
    api_url = "https://api.deepl.com/v2/translate"
    api_key = "INSERT-YOUR-KEY"  # Replace with your actual API key

    data = {
        "auth_key": api_key,
        "text": text,
        "target_lang": target_lang
    }

    response = requests.post(api_url, data=data)

    if response.status_code == 200:
        translation_result = response.json()
        translated_text = translation_result["translations"][0]["text"]
        return translated_text
    else:
        print("Error:", response.status_code, response.text)
        return None


# Function to split long text into smaller parts
# Useful for platforms like Douyin, WeChat, and Aparat
# Splits text by paragraphs (double newlines) while respecting the max_length limit

def split_text_into_parts(text, max_length=300):
    parts = []
    current_part = ''

    for paragraph in re.split(r'\n\n', text):
        if len(current_part) + len(paragraph) <= max_length:
            current_part += paragraph + ' '
        else:
            parts.append(current_part)
            current_part = paragraph + '\n\n'

    if current_part:
        parts.append(current_part)

    return parts


# Set Google Cloud credentials environment variable
# Required to use Google Translate API

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = r'google_credentials.json'


# Function to translate text using Google Cloud Translate API
# Saves the translated text to a specified output file
# Prints the detected source language

def translate_text_google(input_text, target_language, output_file):
    from google.cloud import translate_v2 as translate

    # Initialize the Google Translate client
    translate_client = translate.Client()

    # Perform the translation
    translated_text = translate_client.translate(input_text, target_language=target_language)

    # Save the translated text to a file
    with open(output_file, "w") as file:
        file.write(translated_text["translatedText"])

    # Print the detected source language
    print("Detected source language: {}".format(translated_text["detectedSourceLanguage"]))

    return translated_text


# Function to save the translated text as a markdown file
# Takes the translated text and filename as arguments

def save_translation_as_markdown(translated_text, filename):
    with open(filename, 'w', encoding='utf-8') as file:
        file.write(translated_text)
    print(f"Translation saved to {filename}")


# 1. Example Usage (DeepL)
with open('../data/community-guidelines/6.cn/6.cn.md', "r") as file:
    text=file.read()
print(text)

text_to_translate = text
translated_text = translate_text_deepl(text_to_translate, "EN")  
print(translated_text)

if translated_text:
    save_translation_as_markdown(translated_text, "../data/community-guidelines/6.cn/6.cn_en.md")


# 2. Example Usage (long text - DeepL)
with open('../data/community-guidelines/Douyin/Douyin.md', "r") as file:
    text = file.read()


input_text = text
parts = split_text_into_parts(input_text)


translated_parts = []


for part in parts: 
    part_to_translate = part
    translated_text = translate_text_deepl(part_to_translate, "EN")  
    translated_parts.append(translated_text)


full_translation = ''.join(translated_parts)

if translated_text:
    save_translation_as_markdown(full_translation, "../data/community-guidelines/Douyin/Douyin_en.md")


# 3. Example Usage (Google Cloud Translation)
with open('../data/community-guidelines/Ninisite/Ninisite.md', "r") as file:
    text=file.read()

input_text = text
output_file = '../data/community-guidelines/Ninisite/Ninisite_en.md'
target_language='en'
translate_text_google(input_text, target_language, output_file)
