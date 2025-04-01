#!/usr/bin/env python
# coding: utf-8

import difflib
import json
import logging
import os
import sys

from datetime import datetime

import markdownify
import requests

# cf. https://selenium-python.readthedocs.io/
import selenium
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.firefox.firefox_profile import FirefoxProfile

import pandas as pd

from bs4 import BeautifulSoup
from pypdf import PdfReader

logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s', level=logging.INFO)

### customize!
destination_path = 'data/cgl-temp'

comguide_links = pd.read_csv('data/COMPARE.csv', index_col=0)

### customize!
# firefox_path = 'C:/Program Files/Mozilla Firefox/firefox.exe'
# firefox_path = '/usr/bin/firefox'
firefox_path = '/snap/firefox/current/usr/lib/firefox/firefox'


firefox_options = webdriver.FirefoxOptions()
firefox_profile = FirefoxProfile()
firefox_profile.set_preference('intl.accept_languages', 'en')

firefox_options.add_argument('--enable-javascript')
firefox_options.headless = True
# for headless mode with Selenium 4.8.0/4.10.0,
# see https://www.selenium.dev/blog/2023/headless-is-going-away/
firefox_options.add_argument('--headless')

firefox_options.binary_location = firefox_path

firefox_options.profile = firefox_profile



def cgl_scraper(platform, locator,
                locator2=None, iframe=False, locator3=None, click_button=False,
                text_scrambled=False, locator4=None,
                alt_locator = None,
                make_diff=False, ignore_existing=False,
                write_files=True, name_arg='', return_value=False, additional_link=None,
                options=None, loc_type=By.CSS_SELECTOR,
                md_strip = ['a', 'img']):
    """
    Function to retrive html, text content and metadata from community guidelines pages.

    Args:
    platform (pd.DataFrame): Dataframe containing the name and url of the platform. [To be read from a csv file]
    locator (str): Locator of the element in html source containing the guidelines text. [To be found via inspecting the page source]
    locator2 (str): Locator of the iframe containing the guidelines text. [To be found via inspecting the page source]
    locator3 (str): Locator of the button to click to access the guidelines. [To be found via inspecting the page source]
    locator4 (str): Locator of the element in html source containing the guidelines text- usually used for pages with multiple links and >2 locators. [To be found via inspecting the page source, detected by CLASS_NAME]
    alt_locator (str): Alternative locator of the element in html source containing the guidelines text- usually used for pages with multiple links and >2 locators. [To be found via inspecting the page source]
    options (selenium.webdriver.FirefoxOptions): Options for the Firefox webdriver. [Default: options, defined above]
    locator_strategy (str): Strategy to locate the element in the html source (type of locator). [Default: "CSS_SELECTOR"]
    iframe (bool): If the guidelines are in an iframe. [Default: False]
    click_button (bool): If a button needs to be clicked to access the guidelines, e.g. by expanding text. [Default: False]
    text_scrambled (bool): If the text is scrambled and needs to be extracted from multiple elements. [Default: False]
    make_diff (bool): If a text diff should be created. [Default: False]
    ignore_existing (bool): Forced rescraping even if the destination directory already exists. [Default: False]
    write_files (bool): If the html, text, markdown and metadata should be saved locally. [Default: True]
    name_arg (str): Additional argument to append to the file names.  to differentiate (html) files in cases where we have multiple URLs [Default: empty string]
    return_value (bool): If the text, markdown and metadata should be returned. [Default: False]
    additional_link (str): Link to access the additional links. [Default: None]
    md_strip (list): List of tags to strip from the markdown text. [Default: ['a', 'img']]
    """

    global destination_path
    global firefox_options

    # Define platform name and url:
    name = platform['name'].iloc[0]
    if additional_link != None:
        url = additional_link
    else:
        url = platform['comguide'].iloc[0]

    directory_name = os.path.join(destination_path, name)
    if not (make_diff or ignore_existing) and os.path.exists(directory_name):
        logging.info('Guidelines of %s already done, skipping', name)
        return

    logging.info('Scraping guidelines of %s: %s', name, url)

    # A) Retrieve elements from page:

    # Initialize:
    if options is None:
        options=firefox_options
    driver = webdriver.Firefox(firefox_options)
    driver.get(url)
    logging.info('Fetched guidelines of %s (%.1f kiB): %s (%s)',
                 name, len(driver.page_source)/1024, driver.title, url)

    # iframe handling
    if not iframe: # base strategy (no iframe, can handle pages with differing locators)
        # 2-step try-except block to handle different locators, e.g. for pages with different links & differing locators,
        # to accalerate the process (no need to call function multiple times)
        if click_button:
            button_handler(driver=driver, locator3=locator3)
        try:
            try:
                WebDriverWait(driver, 10).until(
                    EC.presence_of_element_located((loc_type, locator)))
            except:
                locator = alt_locator
                WebDriverWait(driver, 20).until(
                    EC.presence_of_element_located((loc_type, locator)))
        except:
            locator = input()
            WebDriverWait(driver, 20).until(
                    EC.presence_of_element_located((loc_type, locator)))

        # 1) Extracte page source:
        # Yet only html, not CSS / JS elements (?)
        pg_source = driver.page_source
        # html_soup = BeautifulSoup(pg_source, 'html.parser')

    elif iframe:
        # Create catch-all solution for (single level) iframe cases
        # --> Yet only works for colelcting info from iframe, not
        # e.g. for clicking buttons in iframe
        if click_button: # for buttons in iframe (tumblr case)
            WebDriverWait(driver, 20).until(
                EC.presence_of_element_located((loc_type, locator2)))
            iframe_container = driver.find_element(loc_type, locator2)
            iframe = iframe_container.find_element(By.TAG_NAME, 'iframe')
            driver.switch_to.frame(iframe)
            frame_html_soup = BeautifulSoup(driver.page_source, 'html.parser')

            button_handler(driver=driver, locator3=locator3)

            driver.switch_to.default_content()
            try:
                try:
                    WebDriverWait(driver, 10).until(
                        EC.presence_of_element_located((loc_type, locator)))
                except:
                    locator = alt_locator
                    WebDriverWait(driver, 20).until(
                        EC.presence_of_element_located((loc_type, locator)))
            except:
                locator = input()
                WebDriverWait(driver, 20).until(
                        EC.presence_of_element_located((loc_type, locator)))

            # 1) Extracte page source:
            # Yet only html, not CSS / JS elements (?)
            pg_source = driver.page_source
            # html_soup = BeautifulSoup(pg_source, 'html.parser')
        else:
            # Wait for iframe to load:
            WebDriverWait(driver, 20).until(
                EC.presence_of_element_located((loc_type, locator2)))

            pg_source = driver.page_source # get overall page source (outside of the iframe)
            # html_soup = BeautifulSoup(pg_source, 'html.parser')
            iframe_container = driver.find_element(loc_type, locator2)
            iframe = iframe_container.find_element(By.TAG_NAME, 'iframe')
            driver.switch_to.frame(iframe)
            pg_source_frame = driver.page_source # get inner html of iframe
            frame_html_soup = BeautifulSoup(pg_source_frame, 'html.parser')
            WebDriverWait(driver, 20).until(
                EC.presence_of_element_located((loc_type, locator))) # locate text element in iframe:

    # text scambled case: Need for multiple precise locators inside
    # overall content locator - e.g. header and content under
    # different locators
    if text_scrambled:
        overall_elem = driver.find_element(loc_type, locator)

        gl_text = ''
        markdown_text = ''
        # inner_soup = ''
        inner_html = ''

        if isinstance(locator4, list): # if multiple differing locators are needed for the same page, e.g. for header and content
            # locator list must have the locators in the correct order, page-top to bottom
            for loc in locator4:
                try:
                    precise_elem = overall_elem.find_element(loc_type, loc)
                except:
                    loc = input()
                    precise_elem = overall_elem.find_element(loc_type, loc)
                gl_text += precise_elem.get_attribute('textContent')
                elem_html = precise_elem.get_attribute('innerHTML')
                markdown_text += markdownify.markdownify(elem_html, strip=md_strip)
                # inner_soup += BeautifulSoup(elem_html, 'html.parser')
                inner_html += elem_html
        else:
            # case for pages with have the content to scrape in
            # multiple elements but all can be found using the same
            # locator (by CLASS_NAME) - Hatenablog case
            precise_elems = overall_elem.find_elements(By.CLASS_NAME, locator4)
            for elem in precise_elems:
                elem_text = elem.get_attribute('textContent')
                gl_text += '\n\n' + elem_text
                elem_html = elem.get_attribute('innerHTML')
                # elem_soup = BeautifulSoup(elem_html, 'html.parser')
                inner_html += elem_html
                elem_markdown = markdownify.markdownify(elem_html, strip=md_strip)
                markdown_text += '\n\n' + elem_markdown
    else:
        overall_elem = driver.find_element(loc_type, locator)
        gl_text = overall_elem.get_attribute('textContent')
        inner_html = overall_elem.get_attribute('innerHTML')
        # inner_soup = BeautifulSoup(inner_html, 'html.parser')
        markdown_text = markdownify.markdownify(inner_html, strip=md_strip)

    # 3) Creating a text diff:
    # rather for future use case to compare different versions of the same guidelines (yet done in git)
    if make_diff:
        old_file_path = os.path.join(destination_path, name, f'{name}.txt')
        new_text = gl_text
        diff_result = compare_files(old_file_path=old_file_path, new_text=new_text)
        print(diff_result)

    # 4) Collecting meta:
    current_url = driver.current_url
    current_time = datetime.now()
    formatted_time = current_time.strftime('%Y-%m-%d %H:%M:%S')
    meta = {'name': name,
            'url': current_url,
            'timestamp': formatted_time,
            'locator': locator}


    # 5) Close driver:
    driver.quit()

    # B) Save elements locally:
    if write_files:
        logging.info('Saving guidelines %s to %s', name, directory_name)
        if iframe:
            save_local(name=name, name_arg=name_arg,
                       html_source=pg_source, inner_html=inner_html, frame_html=frame_html_soup,
                       cgl_text=gl_text, markdown=markdown_text, metadata=meta)
        else:
            save_local(name=name, name_arg=name_arg,
                       html_source=pg_source, inner_html=inner_html,
                       cgl_text=gl_text, markdown=markdown_text, metadata=meta)

    if return_value:
        return gl_text, markdown_text, meta




def save_local(name, name_arg='', dpath=destination_path,
               html_source=None, inner_html=None, frame_html=None,
               cgl_text=None, markdown=None, metadata=None):
    """
    Function to save html, text content and metadata from community guidelines pages locally.

    Args:
    name (str): Name of the platform.
    name_arg (str): Additional argument to append to the file names. [Default: None]
    dpath (str): Destination path to save the files. [Default: destination_path]
    cgl_text (str): Text content of the guidelines. [Default: None]
    html_source (str): HTML source of the page. [Default: None]
    frame_html (str): HTML source of the iframe. [Default: None]
    inner_html (str): HTML source of the element containing the guidelines text. [Default: None]
    markdown (str): Markdown content of the guidelines. [Default: None]
    metadata (dict): Metadata of the guidelines. [Default: None]
    """

    # Create directory for platform:
    directory_name = os.path.join(dpath, name)
    os.makedirs(directory_name, exist_ok=True)

    # Save html
    if html_source:
        with open(os.path.join(directory_name, name+'_page_source'+name_arg+'.html'),
                  'w', encoding='utf-8') as file:
            file.write(str(html_source))

    # Save additional iframe html (if applicable)
    if frame_html:
        with open(os.path.join(directory_name, name+'_iframe_source'+name_arg+'.html'),
                  'w', encoding='utf-8') as file:
            file.write(str(frame_html))

    # Save text (utf-8)
    if cgl_text:
        with open(os.path.join(directory_name, name+'_cgl'+name_arg+'.txt'),
                  'w',  encoding='utf-8') as f:
            f.write(cgl_text)

    # Save markdown (utf-8)
    if markdown:
        with open(os.path.join(directory_name, name+'_markdown'+name_arg+'.md'),
                  'w', encoding='utf-8') as file:
            file.write(markdown)

    # Save html snippet containing the guidelines:
    if inner_html:
        with open(os.path.join(directory_name, name+'_cgl_source'+name_arg+'.html'),
                  'w', encoding='utf-8') as f:
            f.write(str(inner_html))

    if metadata:
        with open(os.path.join(directory_name, name+'_metadata'+name_arg+'.json'),
                  'w', encoding='utf-8') as f:
            json.dump(metadata, f)


# NEEDS ANOTHER CASE FOR SCAMPLED ADDITIONAL LINKS
# DOES YET NOT HANDLE BUTTON CLICKING IN ADDITIONAL LINKS
# arguments to be included in potential future versions: make_diff=False, iframe=False, click_button=False, locator3=None
def scrape_multiple(platform, locator1, locator2=None, alt_locator=None,
                    name_args=['_1', '_2'], version_name='',
                    text_scrambled=False,  locator4=None,
                    additional_scramble= False, locator5=None,
                    additional_link=None,
                    return_value=False, additional_return=False, loc_type=By.CSS_SELECTOR,
                    ignore_existing=False):
    """
    Function to scrape multiple community guidelines pages and combine them.

    Args:
    platform (pd.DataFrame): Dataframe containing the name and url of the platform. [To be read from a csv file]
    locator1 (str): Locator of the element in html source containing the first guidelines text. [To be found via inspecting the page source]
    locator2 (str): Locator of the element in html source containing the second guidelines text. [To be found via inspecting the page source]
    alt_locator (str): Alternative locator of the element in html source containing the guidelines text- usually used for pages with multiple links and >2 locators. [To be found via inspecting the page source]
    name_args (list): Additional arguments to append to the file names. [Default: ["_1", "_2"]]
    version_name (str): Additional argument to append to the file names. [Default: ""
    text_scrambled (bool): If the text is scrambled and needs to be extracted from multiple elements. [Default: False]
    locator4 (str): Locator of the element in html source containing the guidelines text- usually used for pages with multiple links and >2 locators. [To be found via inspecting the page source, detected by CSS_SELECTOR if List, else by.CLASS_NAME]
    make_diff (bool): If a text diff should be created. [Default: False]
    additional_link (str): Link to access the additional links. [Default: None]
    additional_scamble (bool): If the additional links are scabled. [Default: False]
    locator5 (str): Locator of the element in html source containing the guidelines text- usually used for pages with multiple links and >2 locators. [To be found via inspecting the page source, detected by CSS_SELECTOR if List, else by.CLASS_NAME]
    return_value (bool): If the text, markdown and metadata should be returned. [Default: False]
    additional_return (bool): If the text, markdown and metadata of the additional link should be returned. [Default: False]
    loc_type (str): Strategy to locate the element in the html source (type of locator). [Default: "CSS_SELECTOR"]
    """

    name = platform['name'].iloc[0]
    directory_name = os.path.join(destination_path, name)
    if not ignore_existing and os.path.exists(directory_name):
        logging.info('Guidelines of %s already done, skipping', name)
        return

    if text_scrambled:
        cgl_text1, markdown1, meta1 = cgl_scraper(
            platform=platform, locator=locator1,
            text_scrambled=True, locator4=locator4,
            name_arg=name_args[0]+version_name,
            return_value=True, ignore_existing=True)
    else:
        cgl_text1, markdown1, meta1 = cgl_scraper(
            platform=platform, locator=locator1,
            name_arg=name_args[0]+version_name,
            return_value=True, ignore_existing=True)

    meta = None

    # Getting additional link:

    # working with a list of additional links
    if additional_scramble:
        if isinstance(additional_link, list):
            for i, link in enumerate(additional_link):
                try:
                    cgl_text2, markdown2, meta2 = cgl_scraper(
                        platform=platform, locator=locator2,
                        name_arg='_'+str(i)+version_name,
                        return_value=True, ignore_existing=True,
                        additional_link=link, alt_locator=alt_locator, text_scrambled=True,
                        locator4=locator5, loc_type=loc_type)
                except:
                    alt_locator = input()
                    cgl_text2, markdown2, meta2 = cgl_scraper(
                        platform=platform, locator=alt_locator,
                        name_arg='_'+str(i)+version_name,
                        return_value=True, ignore_existing=True,
                        additional_link=link, text_scrambled=True,
                        locator4=locator5, loc_type=loc_type)

                cgl_text = cgl_text1 + '\n\n' + cgl_text2
                cgl_text1 = cgl_text
                markdown = markdown1 + '\n\n' + markdown2
                markdown1 = markdown
                if isinstance(meta, list):
                    meta.append(meta2)
                else:
                    meta = [meta1, meta2]


        else:
            cgl_text2, markdown2, meta2 = cgl_scraper(
                platform=platform, locator=locator2,
                name_arg=name_args[1]+version_name,
                return_value=True, ignore_existing=True,
                additional_link=additional_link, text_scrambled=True,
                locator4=locator5, loc_type=loc_type)
    else:
        if isinstance(additional_link, list):
            for i, link in enumerate(additional_link):
                try:
                    cgl_text2, markdown2, meta2 = cgl_scraper(
                        platform=platform, locator=locator2,
                        name_arg='_'+str(i)+version_name,
                        return_value=True, ignore_existing=True,
                        additional_link=link, alt_locator=alt_locator, loc_type=loc_type)
                except:
                    alt_locator = input()
                    cgl_text2, markdown2, meta2 = cgl_scraper(
                        platform=platform, locator=alt_locator,
                        name_arg='_'+str(i)+version_name,
                        return_value=True, ignore_existing=True,
                        additional_link=link, loc_type=loc_type)

                cgl_text = cgl_text1 + '\n\n' + cgl_text2
                cgl_text1 = cgl_text
                markdown = markdown1 + '\n\n' + markdown2
                markdown1 = markdown
                if isinstance(meta, list):
                    meta.append(meta2)
                else:
                    meta = [meta1, meta2]

        else:
            cgl_text2, markdown2, meta2 = cgl_scraper(
                platform=platform, locator=locator2,
                name_arg=name_args[1]+version_name,
                return_value=True, ignore_existing=True,
                additional_link=additional_link, loc_type=loc_type)

            # Appending the texts, markdowns and metadata:
            cgl_text = cgl_text1 + '\n\n' + cgl_text2
            markdown = markdown1 + '\n\n' + markdown2
            meta = [meta1, meta2]

    # Saving the combined text, markdown and metadata:
    save_local(name=platform['name'].iloc[0], cgl_text=cgl_text,
               markdown=markdown, metadata=meta, name_arg=version_name)
    if additional_return==True and return_value==True:
        return cgl_text1, markdown1, meta1, cgl_text2, markdown2, meta2
    if return_value==True and additional_return==False:
        return cgl_text, markdown, meta
    if return_value==False and additional_return==True:
        return cgl_text2, markdown2, meta2




def button_handler(driver, locator3=None):
    """
    Function to handle button clicking in selenium.

    Args:
    locator3 (str): Locator of the button to click. [To be found via inspecting the page source]
    driver (selenium.webdriver): Selenium webdriver. [Default: driver]
    """
    if isinstance(locator3, list):
            for b in locator3:
                try:
                    WebDriverWait(driver, 10).until(
                        EC.element_to_be_clickable((By.CSS_SELECTOR, b)))

                    # handling multiple clicks on buttons with common identifier:
                    buttons = driver.find_elements(By.CSS_SELECTOR, b)
                    for button in buttons:
                        driver.execute_script('arguments[0].scrollIntoView(true);', button)
                        button.click()
                except:
                    continue
    else:
        WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.CSS_SELECTOR, locator3)))

        # handling multiple clicks on buttons with common identifier:
        buttons = driver.find_elements(By.CSS_SELECTOR, locator3)
        for button in buttons:
            driver.execute_script('arguments[0].scrollIntoView(true);', button)
            try:
                driver.execute_script('arguments[0].click();', button)
            except:
                button.click()



# Making the local diff

def compare_files(old_file_path, new_text):
    with open(old_file_path, 'r', encoding='utf-8') as file_old:
        old_text = str(file_old.readlines())

    diff = difflib.unified_diff(old_text.splitlines(), new_text.splitlines(), lineterm='')

    return '\n'.join(list(diff))


################################################################################
#### Run over platforms ########################################################
################################################################################


#### WhatsApp

platform = comguide_links[comguide_links['name'] == 'WhatsApp']
locator = '#content-wrapper'

cgl_scraper(platform=platform, locator=locator)


#### Pinterest
# (part of pga-versions)
# platform = comguide_links[comguide_links['name'] == 'Pinterest']
# locator = '.css-1fe8m2o'
# cgl_scraper(platform=platform, locator=locator)


#### Tumblr

platform = comguide_links[comguide_links['name'] == 'Tumblr']
locator = '.l-content'
locator2 = '.cmp-components-modal__screen-overlay'
locator3 = 'button.cmp-components-button:nth-child(2)' # button in frame

cgl_scraper(platform=platform, locator=locator, locator2=locator2, locator3=locator3,
            iframe=True, click_button=True)


#### Flickr - special case (text embedded in PDF)

platform = comguide_links[comguide_links['name'] == 'Flickr']
name = platform['name'].iloc[0]
directory_name = os.path.join(destination_path, name)
if os.path.exists(directory_name):
    logging.info('Guidelines of %s already done, skipping', name)
else:
    url = platform['comguide'].iloc[0]
    logging.info('Scraping guidelines of %s: %s', name, url)
    locator = '#yui_3_16_0_1_1723538816088_539'
    flickr_path = os.path.join(destination_path, name, name)

    # Scrape pdf, save and write it to .txt - also saves html and meta data
    driver = webdriver.Firefox(firefox_options)
    driver.get(url)

    pg_source = driver.page_source

    pdf_element = driver.find_element(By.CLASS_NAME, 'help-pdf')
    pdf_url = pdf_element.get_attribute('data')

    current_time = datetime.now()
    formatted_time = current_time.strftime('%Y-%m-%d %H:%M:%S')
    meta = {'name': name,
            'url': url,
            'timestamp': formatted_time,
            'locator': locator}

    save_local(name=name, metadata=meta, html_source=pg_source)

    # download pdf containing the guideline text:
    response = requests.get(pdf_url)
    pdf = open(flickr_path+'_pdf.pdf', 'wb')
    pdf.write(response.content)
    pdf.close()

    driver.quit()

    ## Parsing text from flickr pdf:
    with open(flickr_path+'_pdf.pdf', 'rb') as pdf_file:
        pdf_reader = PdfReader(pdf_file)
        gl_text = ''
        for page_num in range(len(pdf_reader.pages)):
            page = pdf_reader.pages[page_num]
            gl_text += page.extract_text()

            gl_text = ' '.join(gl_text.splitlines())

        with open(flickr_path+'.txt', 'w', encoding='utf-8') as txt_file:
            txt_file.write(gl_text)


#### Dxy

platform = comguide_links[comguide_links['name'] == 'Dxy']
locator = '.wrap___2JIuz'

cgl_scraper(platform=platform, locator=locator)


#### 6.cn

platform = comguide_links[comguide_links['name'] == '6.cn']
locator = '.service-box'

cgl_scraper(platform=platform, locator=locator)


#### Zhanqi

platform = comguide_links[comguide_links['name'] == 'Zhanqi.tv']
locator = '.tutorial-bd'

cgl_scraper(platform=platform, locator=locator)


#### CSDN

platform = comguide_links[comguide_links['name'] == 'CSDN']
locator = '#content_views'

cgl_scraper(platform=platform, locator=locator)


#### YY - case-specific solution (could be added to function later - but yet only for this platform needed)

platform = comguide_links[comguide_links['name'] == 'YY']
name = platform['name'].iloc[0]
directory_name = os.path.join(destination_path, name)
if os.path.exists(directory_name):
    logging.info('Guidelines of %s already done, skipping', name)
else:
    url = platform['comguide'].iloc[0]
    logging.info('Scraping guidelines of %s: %s', name, url)
    locator = '.news__detail__content'
    additional_link = 'https://www.yy.com/n/33_153.html'
    locator2 = locator
    YY_path = os.path.join(destination_path, name.upper(), name.upper())

    urls = [url, additional_link]
    name_args = ['_1', '_2']

    # combine both pages (text + markdown)
    gl_text_all = ''
    inner_html_all = ''
    markdown_text_all = ''
    meta_all = []

    for i, url_i in enumerate(urls):
        driver = webdriver.Firefox(firefox_options)
        driver.get(url_i)

        # per page:
        pg_source = driver.page_source
        gl_text = ''
        inner_html = ''

        # Overall text block holen und links im textblock suchen
        overall_elem = driver.find_elements(By.CLASS_NAME, 'news__detail__content')
        for elem in overall_elem:
            gl_text += elem.get_attribute('textContent')
            inner_html += elem.get_attribute('innerHTML')

        # inner_soup = BeautifulSoup(inner_html, 'html.parser')
        markdown_text = markdownify.markdownify(inner_html, strip=['a', 'img'])

        current_time = datetime.now()
        formatted_time = current_time.strftime('%Y-%m-%d %H:%M:%S')
        meta = {'name': name,
                'url': url_i,
                'timestamp': formatted_time,
                'locator': locator}

        driver.quit()
        save_local(name=name, metadata=meta, html_source=pg_source, inner_html=inner_html,
                   cgl_text=gl_text, markdown=markdown_text, name_arg=name_args[i])

        gl_text_all += gl_text
        inner_html_all += inner_html
        markdown_text_all += markdown_text
        meta_all.append(meta)

        save_local(name=name, metadata=meta_all, inner_html=inner_html_all, cgl_text=gl_text_all,
                   markdown=markdown_text_all)


#### Slug

platform = comguide_links[comguide_links['name'] == 'Slug']
locator = '.last_event'

res = cgl_scraper(platform=platform, locator=locator, return_value=True)
if res:
    cgl_text0, markdown0, meta0 = res
    # manuall text cleaning
    cgl_text1 = cgl_text0.split('Join now and join the conversation!', 1)[1]
    markdown_text1 = markdown0.split('Join now and join the conversation!', 1)[1]

    save_local(name=platform['name'].iloc[0], cgl_text=cgl_text1, markdown=markdown_text1)


#### Gettr

platform = comguide_links[comguide_links['name'] == 'Gettr']
locator = '.jss338' # OLD locator: '.jss299'

res = cgl_scraper(platform=platform, locator=locator, return_value=True)
if res:
    cgl_text0, markdown0, meta0 = res

    cgl_before_contents = cgl_text0.split('ContentsHarassment and Bullying')[0]
    cgl_after_harassment = cgl_text0.split('Harassment and BullyingDo')[1]
    cgl_text1 = cgl_before_contents + '\n' + ' Harassment and Bullying' + '\n' + 'Do' +  cgl_after_harassment

    markdown_before_contents = markdown0.split('Contents')[0]
    markdown_after_harassment = markdown0.split('### Harassment and Bullying')[1]
    markdown_text1 = markdown_before_contents + '\n' '### Harassment and Bullying' + '\n' +  markdown_after_harassment

    save_local(name=platform['name'].iloc[0], cgl_text=cgl_text1, markdown=markdown_text1)


#### Hive Social

platform = comguide_links[comguide_links['name'] == 'Hive Social']
locator = 'div.section:nth-child(4) > div:nth-child(1)'

cgl_scraper(platform=platform, locator=locator)


#### Yubo

platform = comguide_links[comguide_links['name'] == 'Yubo']
locator = '.css-1wtzs2q'
additional_link='https://www.yubo.live/safety/advice'
locator2 = '.css-zwja0g'

scrape_multiple(platform=platform, locator1=locator, locator2=locator2, additional_link=additional_link)


#### 8kun

platform = comguide_links[comguide_links['name'] == '8kun']
locator = '.ban'
additional_link='https://8kun.top/dost.html'

scrape_multiple(platform=platform, locator1=locator, locator2=locator, additional_link=additional_link)


#### ThinkSpot

platform = comguide_links[comguide_links['name'] == 'ThinkSpot']
locator = '.container'

res = cgl_scraper(platform=platform, locator=locator, return_value=True)
if res:
    cgl_text0, markdown0, meta0 = res

    # manual text cleaning
    cgl_text1 = cgl_text0.split('I18n.locale')[0]
    markdown1 = markdown0.split('*close*')[0]
    save_local(name=platform['name'].iloc[0], cgl_text=cgl_text1, markdown=markdown1)


#### Foursquare

platform = comguide_links[comguide_links['name'] == 'Foursquare']
locator = '#blankPage'
# locator2 = '.sc-jKmXuR'

cgl_scraper(platform=platform, locator=locator)


#### Triller

platform = comguide_links[comguide_links['name'] == 'Triller']
locator = '.betterdocs-content-inner-area'

res = cgl_scraper(platform=platform, locator=locator, return_value=True)
if res:
    cgl_text0, markdown0, meta0 = res

    # manual text cleaning
    cgl_text1 = cgl_text0.split('Community Guidelines', 1)[1]
    cgl_text1 = cgl_text1.split('Was this article helpful?')[0]

    markdown1 = markdown0.split('* Community Guidelines')[1]
    markdown1 = markdown1.split('##### Was this article helpful?')[0]
    save_local(name=platform['name'].iloc[0], cgl_text=cgl_text1, markdown=markdown1)


#### Nextdoor

platform = comguide_links[comguide_links['name'] == 'Nextdoor']
locator = 'div.slds-size--12-of-12:nth-child(1) > div:nth-child(1) > div:nth-child(2)'
locator4 = ['div.cArticleDetail:nth-child(1)', '#articlecontent']

additional_links = [
    'https://help.nextdoor.com/s/article/Be-respectful-to-your-neighbors?language=en_US#civil',
    'https://help.nextdoor.com/s/article/Do-not-discriminate?language=en_US',
    'https://help.nextdoor.com/s/article/Be-helpful-in-conversations?language=en_US',
    'https://help.nextdoor.com/s/article/use-your-true-identity?language=en_US',
    'https://help.nextdoor.com/s/article/Do-not-engage-in-harmful-activity?language=en_US',
    'https://help.nextdoor.com/s/article/Hate-Groups?language=en_US',
    'https://help.nextdoor.com/s/article/List-of-prohibited-goods-and-services?language=en_US'
]

# locator2 = locator #"div.slds-size--12-of-12:nth-child(1) > div:nth-child(1) > div:nth-child(2)" #( Title, Content, but also "was this helpful banner") # "#articlecontent" # (only content, but no header)
# locator5 = locator4

scrape_multiple(platform=platform, locator1=locator, locator2=locator, text_scrambled=True, locator4=locator4, additional_scramble=True, locator5=locator4, additional_link=additional_links)


#### Vero

platform = comguide_links[comguide_links['name'] == 'Vero']
locator = '#vero-community-guidelines'

res = cgl_scraper(platform=platform, locator=locator, return_value=True)
if res:
    cgl_text0, markdown0, meta0 = res

    # manual text cleaning
    cgl_text1 = cgl_text0.split('Русский')[1]
    markdown1 = markdown0.split('Русский')[1]
    save_local(name=platform['name'].iloc[0], cgl_text=cgl_text1, markdown=markdown1)


#### Minds

platform = comguide_links[comguide_links['name'] == 'Minds']
locator = '.m-marketing__mainWrapper'

cgl_scraper(platform=platform, locator=locator)


#### Josh

platform = comguide_links[comguide_links['name'] == 'Josh']
locator = '.PT30'

res = cgl_scraper(platform=platform, locator=locator, return_value=True)
if res:
    cgl_text0, markdown0, meta0 = res

    # manuall text cleaning
    cgl_text1 = cgl_text0.split('You may contact:', 1)[0]
    cgl_text1 = cgl_text1.split('Updated in November 2023', 1)[1]

    markdown_text1 = markdown0.split('You may contact:', 1)[0]
    save_local(name=platform['name'].iloc[0], cgl_text=cgl_text1, markdown=markdown_text1)


#### Knuddels

platform = comguide_links[comguide_links['name'] == 'Knuddels']
locator = 'main.w-full'
additional_links = [
    'https://hilfe.knuddels.de/de/articles/3714039-gegen-extremismus-fur-toleranz-und-akzeptanz',
    'https://hilfe.knuddels.de/de/articles/8850196-umgang-mit-beleidigung-und-provokation-in-der-knuddels-community',
    'https://hilfe.knuddels.de/de/articles/8811212-vor-belastigung-schutzen-und-hilfe-finden',
    'https://hilfe.knuddels.de/de/articles/8779132-umgang-mit-mobbing-in-der-knuddels-community',
    'https://hilfe.knuddels.de/de/articles/8837073-rechtswidrige-verstosse-melden',
    'https://www.knuddels.de/fotoregeln'
]
locator2 = '.article'
alt_locator = '.rich-text' # input as alternative locator

scrape_multiple(platform=platform, locator1=locator, locator2=locator2,
                alt_locator=alt_locator, additional_link=additional_links)


#### Ninisite - Additional link not working

platform = comguide_links[comguide_links['name'] == 'Ninisite']
locator = 'div.container:nth-child(4)'
additional_link = 'http://internet.ir/crime_index.html'

scrape_multiple(platform=platform, locator1=locator, locator2=locator, additional_link=additional_link)


#### Imo

platform = comguide_links[comguide_links['name'] == 'Imo']
locator = '#wrapper'

cgl_scraper(platform=platform, locator=locator)


#### Peanut

platform = comguide_links[comguide_links['name'] == 'Peanut']
locator = '.text-page'

cgl_scraper(platform=platform, locator=locator)


#### DLive

platform = comguide_links[comguide_links['name'] == 'DLive']
locator = '.vc_col-sm-9'

cgl_scraper(platform=platform, locator=locator)


#### WeChat

platform = comguide_links[comguide_links['name'] == 'WeChat']
locator = '#agreement'

additional_links = [
    'https://safety.wechat.com/zh_CN/community-guidelines/introduction',
    'https://safety.wechat.com/zh_CN/community-guidelines/cover/fraud-or-scams',
    'https://safety.wechat.com/zh_CN/community-guidelines/cover/nudity-or-sexual-content',
    'https://safety.wechat.com/zh_CN/community-guidelines/cover/hateful-spam-or-other-inappropriate-behaviour',
    'https://safety.wechat.com/zh_CN/community-guidelines/cover/violent-content',
    'https://safety.wechat.com/zh_CN/community-guidelines/cover/account-integrity',
    'https://safety.wechat.com/zh_CN/community-guidelines/cover/intellectual-property-infringement',
    'https://safety.wechat.com/zh_CN/community-guidelines/cover/minor-safety',
    'https://safety.wechat.com/zh_CN/community-guidelines/cover/terrorism-violent-extremism-and-other-criminal-behaviour',
    'https://safety.wechat.com/zh_CN/community-guidelines/cover/personal-data-violation',
    'https://safety.wechat.com/zh_CN/community-guidelines/cover/other-inappropriate-content'
]
locator2 = '.weui-article'

scrape_multiple(platform=platform, locator1=locator, locator2=locator2, additional_link=additional_links)


#### Vk

platform = comguide_links[comguide_links['name'] == 'VK']
locator = '.article_layer__views'

cgl_scraper(platform=platform, locator=locator)


#### ReverbNation

platform = comguide_links[comguide_links['name'] == 'ReverbNation']
locator = '.content-container'

cgl_scraper(platform=platform, locator=locator)


#### Tellonym

platform = comguide_links[comguide_links['name'] == 'Tellonym']
locator = '.docsie-section-conatiner'
additional_link = 'https://help.tellonym.me/hc/en-us/articles/360008791820-Picture-Guidelines'
locator = '.article'

res  = scrape_multiple(platform=platform, locator1=locator, locator2=locator,
                       additional_link=additional_link, return_value=True, additional_return=True)
if res:
    cgl_text01, markdown01, meta1, cgl_text02, markdown02, meta2 = res

    # manuall text cleaning
    cgl_text1 = cgl_text01.split('Facebook')[0]
    cgl_text2 = cgl_text02.split('Facebook')[0]
    cgl_text = cgl_text1 + '\n' + cgl_text2

    markdown1 = markdown01.split('* Facebook')[0]
    markdown2 = markdown02.split('* Facebook')[0]
    markdown = markdown1 + '\n' + markdown2
    save_local(name=platform['name'].iloc[0], cgl_text=cgl_text, markdown=markdown)


#### Likee

platform = comguide_links[comguide_links['name'] == 'Likee']
locator = '.community-panel-wrap'

cgl_scraper(platform=platform, locator=locator, options=None)


#### Ask.fm

platform = comguide_links[comguide_links['name'] == 'Ask.fm']
locator = '.entry-content > div:nth-child(1)'

cgl_scraper(platform=platform, locator=locator)


#### Plurk

platform = comguide_links[comguide_links['name'] == 'Plurk']
locator = '#privacy'

cgl_scraper(platform=platform, locator=locator)


#### Aparat

platform = comguide_links[comguide_links['name'] == 'Aparat']
locator = '.sc-iWBNLc'
locator4 = ['.hs-title', '.static-paragraph', '.section-publish']

additional_links = [
    'https://www.aparat.com/community-guideline/publishPolicy/nonObservancePrivacy/',
    'https://www.aparat.com/community-guideline/publishPolicy/dangerousContent',
    'https://www.aparat.com/community-guideline/publishPolicy/sensitiveContent',
    'https://www.aparat.com/community-guideline/publishPolicy/promoteBehavior',
    'https://www.aparat.com/community-guideline/publishPolicy/securityConsiderations','https://www.aparat.com/community-guideline/publishPolicy/misleadingContent',
    'https://www.aparat.com/community-guideline/publishPolicy/offensiveContent',
    'https://www.aparat.com/community-guideline/publishPolicy/copyright'
]
locator2 = '.static-content'

scrape_multiple(platform=platform, locator1=locator, locator2=locator2, text_scrambled=True, locator4=locator4, additional_link=additional_links)


#### Hacker News

platform = comguide_links[comguide_links['name'] == 'Hacker News']
locator = 'body > center:nth-child(1)'

cgl_scraper(platform=platform, locator=locator)


#### Tagged

platform = comguide_links[comguide_links['name'] == 'Tagged']
locator = '.member-diamonds-educate'

cgl_scraper(platform=platform, locator=locator)


#### Xing

platform = comguide_links[comguide_links['name'] == 'Xing']
locator = '#block-xingskin-content'

cgl_scraper(platform=platform, locator=locator)


#### Viber

platform = comguide_links[comguide_links['name'] == 'Viber']
locator = '.main'

cgl_scraper(platform=platform, locator=locator)


#### BitChute

platform = comguide_links[comguide_links['name'] == 'BitChute']
# locator = '.helpjuice-article-body-content'
locator = '#js_page_content'
locator4 = ['.question_title', '.helpjuice-article-body-content']

additional_links = [
    'https://support.bitchute.com/policy/prohibited-entities-list',
    'https://support.bitchute.com/policy-explanations/incitement-to-hatred'
]

locator5 = ['.question_title', '.helpjuice-article-body-content']


scrape_multiple(platform=platform, locator1=locator, locator2=locator, additional_link=additional_links,
                text_scrambled=True, locator4=locator4, additional_scramble=True, locator5=locator5,
                version_name='_clean')


#### NewGrounds

platform = comguide_links[comguide_links['name'] == 'NewGrounds']
locator = '.ql-body'

additional_links = [
    'https://www.newgrounds.com/wiki/help-information/terms-of-use/audio-guidelines',
    'https://www.newgrounds.com/wiki/help-information/terms-of-use/game-guidelines',
    'https://www.newgrounds.com/wiki/help-information/terms-of-use/movie-guidelines',
    'https://www.newgrounds.com/wiki/help-information/terms-of-use/art-guidelines',
    'https://www.newgrounds.com/wiki/help-information/terms-of-use/blog-guidelines'
]
locator2 = 'div.column:nth-child(5)'

scrape_multiple(platform=platform, locator1=locator, locator2=locator2, additional_link=additional_links)


#### Odysee

platform = comguide_links[comguide_links['name'] == 'Odysee']
locator = '.theme-doc-markdown'

cgl_scraper(platform=platform, locator=locator)


#### VSCO

platform = comguide_links[comguide_links['name'] == 'VSCO']
locator = '.padding-global'

cgl_scraper(platform=platform, locator=locator)


#### Kuaishou

platform = comguide_links[comguide_links['name'] == 'Kuaishou']
locator = '.norm-content'

cgl_scraper(platform=platform, locator=locator)


#### Letterboxd

platform = comguide_links[comguide_links['name'] == 'Letterboxd']
locator = '.content'

cgl_scraper(platform=platform, locator=locator)


#### Bainly

platform = comguide_links[comguide_links['name'] == 'Brainly']
locator = 'body'
locator4 = ['section.hero:nth-child(1) > div:nth-child(1) > div:nth-child(1)', '.values > div:nth-child(2)',
            'section.columns:nth-child(4)', 'section.columns:nth-child(5) > div:nth-child(1) > div:nth-child(1)']

cgl_scraper(platform=platform, locator=locator, locator4=locator4, text_scrambled=True)


#### Behance

platform = comguide_links[comguide_links['name'] == 'Behance']
locator = '.Legal-primaryContent-es7'
additional_link = 'https://help.behance.net/hc/en-us/articles/204485024-Guide-Adult-Content-on-Behance '
locator2 = '.article'

scrape_multiple(platform=platform, locator1=locator, locator2=locator2, additional_link=additional_link)


#### Wykop

platform = comguide_links[comguide_links['name'] == 'Wykop']
locator = 'main.main > section:nth-child(1) > div:nth-child(1)'

cgl_scraper(platform=platform, locator=locator)


#### Badoo

platform = comguide_links[comguide_links['name'] == 'Badoo']
locator = '.terms-view'

additional_links = [
    'https://badoo.com/guidelines/nudity-sexual-activity#guidelines',
    'https://badoo.com/guidelines/bullying#guidelines',
    'https://badoo.com/guidelines/child-exploitation-abuse#guidelines',
    'https://badoo.com/guidelines/commercial-promotional#guidelines',
    'https://badoo.com/guidelines/dangerous-organizations-individuals/#guidelines',
    'https://badoo.com/guidelines/inauthentic-profiles#guidelines',
    'https://badoo.com/guidelines/goods-substances#guidelines',
    'https://badoo.com/guidelines/misinformation#guidelines',
    'https://badoo.com/guidelines/physical-sexual-violence#guidelines',
    'https://badoo.com/guidelines/scams-theft#guidelines',
    'https://badoo.com/guidelines/sexual-harassment#guidelines',
    'https://badoo.com/guidelines/spam#guidelines',
    'https://badoo.com/guidelines/suicide-self-injury#guidelines',
    'https://badoo.com/guidelines/violent-graphic-content#guidelines'
]

# locator2 = '.terms-view'
scrape_multiple(platform=platform, locator1=locator, locator2=locator, additional_link=additional_links)


#### 4chan

platform = comguide_links[comguide_links['name'] == '4chan']
locator = 'div.right-box:nth-child(1) > div:nth-child(1)'

# issue: detects browser as automated
# manual approach using the copy- pasted inner_html due to autmatic browser detection:
name = platform['name'].iloc[0]
directory_name = os.path.join(destination_path, name)
if os.path.exists(directory_name):
    logging.info('Guidelines of %s already done, skipping', name)

else:
    cgl_scraper(platform=platform, locator=locator)

    inner_html = None
    with open(os.path.join(directory_name, '4chan_cgl_source.html'),
              'r', encoding='utf-8') as file:
        inner_html = file.read()

    markdown_text = markdownify.markdownify(inner_html, strip=['a', 'img'])

    soup = BeautifulSoup(inner_html, 'html.parser')
    gl_text = soup.get_text()

    current_time = datetime.now()
    formatted_time = current_time.strftime('%Y-%m-%d %H:%M:%S')

    meta = {'name': platform['name'].iloc[0],
            'url': platform['comguide'].iloc[0],
            'timestamp': formatted_time,
            'locator': None}

    save_local(name=platform['name'].iloc[0], markdown=markdown_text,
               cgl_text=gl_text, metadata=meta, inner_html=inner_html)


#### Fetlife - text isn't really clean because of difficult to filter headers

platform = comguide_links[comguide_links['name'] == 'Fetlife']
locator = 'div.py-6:nth-child(1)'

additional_links = [
    'https://fetlife.com/guidelines/content-guidelines-rjym3', # not really on content just top-level page organizing single cgl content pages (would require additional text cleaning)
    'https://fetlife.com/guidelines/content-guidelines/minors-csa-and-csam-ln8wu',
    # hateful conduct links:
    'https://fetlife.com/guidelines/content-guidelines/hateful-conduct/gender-shaming-fthes',
    'https://fetlife.com/guidelines/content-guidelines/hateful-conduct/orientation-shaming-6p5tq',
    'https://fetlife.com/guidelines/content-guidelines/hateful-conduct/antisemitism-nrtla',
    'https://fetlife.com/guidelines/content-guidelines/hateful-conduct/hateful-slurs-qggdw',
    'https://fetlife.com/guidelines/content-guidelines/hateful-conduct/body-shaming-vwote',
    'https://fetlife.com/guidelines/content-guidelines/hateful-conduct/kink-shaming-0xvnk',
    'https://fetlife.com/guidelines/content-guidelines/hateful-conduct/aggressive-personal-attack-cveme',
    # privacy links:
    'https://fetlife.com/guidelines/content-guidelines/privacy-concerns/doxing-ywlkx',
    'https://fetlife.com/guidelines/content-guidelines/privacy-concerns/outing-zyoyp',
    'https://fetlife.com/guidelines/content-guidelines/privacy-concerns/revenge-porn-cyohf',
    'https://fetlife.com/guidelines/content-guidelines/privacy-concerns/person-in-picture-video-fcmb6',
    'https://fetlife.com/guidelines/content-guidelines/privacy-concerns/posting-content-off-site-ktepj',
    'https://fetlife.com/guidelines/content-guidelines/privacy-concerns/personally-identifiable-information-vrgdg',
    'https://fetlife.com/guidelines/content-guidelines/privacy-concerns/sock-puppet-accounts-nfp9k',
    'https://fetlife.com/guidelines/content-guidelines/privacy-concerns/screenshot-2hv0e',
    'https://fetlife.com/guidelines/content-guidelines/privacy-concerns/spotting-dsefp',
    'https://fetlife.com/guidelines/content-guidelines/privacy-concerns/flro-fgdbc',
    # safety concerns:
    'https://fetlife.com/guidelines/content-guidelines/safety-concerns/registered-sex-offender-vmone',
    'https://fetlife.com/guidelines/content-guidelines/safety-concerns/threat-of-violence-zswkm',
    'https://fetlife.com/guidelines/content-guidelines/safety-concerns/animal-cruelty-ylsea',
    'https://fetlife.com/guidelines/content-guidelines/safety-concerns/bestiality-wurep',
    'https://fetlife.com/guidelines/content-guidelines/safety-concerns/team-member-impersonation-ytn0l',
    'https://fetlife.com/guidelines/content-guidelines/safety-concerns/eating-disorders-ugumu',
    'https://fetlife.com/guidelines/content-guidelines/safety-concerns/sti-std-vzxbl',
    # prohibited exchanges:
    'https://fetlife.com/guidelines/content-guidelines/prohibited-exchanges/exchange-of-sex-acts-i2lrh',
    'https://fetlife.com/guidelines/content-guidelines/prohibited-exchanges/exchange-of-drugs-zmuck',
    # content restrictions:
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/incest-play-7tc1d',
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/snuff-necro-play-yc7cx',
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/cannibalism-play-iek9n',
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/mutilation-play-yesph',
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/dark-fantasy-play-a0hui',
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/scat-play-bxpmf',
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/blood-play-p6voj',
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/gun-play-cpbsv',
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/clickbait-ivmzo',
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/keyword-spam-zmqrp',
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/friend-following-limits-fdqdo',
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/groups-sptru',
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/group-ownership-etc6q',
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/events-ouo9f',
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/commercial-profiles-ntpyq',
    'https://fetlife.com/guidelines/content-guidelines/content-restrictions/copyright-j7fly'
]

locator2 = '.max-w-2xl'

scrape_multiple(platform=platform, locator1=locator, locator2=locator2, additional_link=additional_links)

locator = 'div.py-6:nth-child(1)'  # TODO: maybe the better extract


#### Kwai

platform = comguide_links[comguide_links['name'] == 'Kwai']
locator = '.common-rich-text'
locator2 = '.safety-right'

cgl_scraper(platform=platform, locator=locator, locator2=locator2, iframe=True)


#### Slideshare

platform = comguide_links[comguide_links['name'] == 'SlideShare']
locator = '.content'
additional_link = 'https://support.scribd.com/hc/en-us/articles/210129166-Community-Rules-Prohibited-Activity-and-Content'

scrape_multiple(platform=platform, locator1=locator, locator2=locator, additional_link=additional_link)


#### Vimeo

platform = comguide_links[comguide_links['name'] == 'Vimeo']
locator = '.otnotice-content'

locator3 = [
    '#otnotice-section-e043a136-9048-46f3-9972-30301b200d8e > div:nth-child(1) > p:nth-child(7) > a:nth-child(1)', '#otnotice-section-e043a136-9048-46f3-9972-30301b200d8e > div:nth-child(1) > ul:nth-child(10) > li:nth-child(1) > a:nth-child(1)',
    '#otnotice-section-e043a136-9048-46f3-9972-30301b200d8e > div:nth-child(1) > ul:nth-child(11) > li:nth-child(1) > a:nth-child(1)', '#otnotice-section-e043a136-9048-46f3-9972-30301b200d8e > div:nth-child(1) > ul:nth-child(12) > li:nth-child(1) > a:nth-child(1)',
    '#otnotice-section-e043a136-9048-46f3-9972-30301b200d8e > div:nth-child(1) > ul:nth-child(13) > li:nth-child(1) > a:nth-child(1)', '#otnotice-section-e043a136-9048-46f3-9972-30301b200d8e > div:nth-child(1) > ul:nth-child(14) > li:nth-child(1) > a:nth-child(1)',
    '#otnotice-section-e043a136-9048-46f3-9972-30301b200d8e > div:nth-child(1) > ul:nth-child(15) > li:nth-child(1) > a:nth-child(1)', '#otnotice-section-e043a136-9048-46f3-9972-30301b200d8e > div:nth-child(1) > ul:nth-child(16) > li:nth-child(1) > a:nth-child(1)',
    '#otnotice-section-e043a136-9048-46f3-9972-30301b200d8e > div:nth-child(1) > ul:nth-child(17) > li:nth-child(1) > a:nth-child(1)', '#otnotice-section-e043a136-9048-46f3-9972-30301b200d8e > div:nth-child(1) > ul:nth-child(18) > li:nth-child(1) > a:nth-child(1)',
    '#otnotice-section-e043a136-9048-46f3-9972-30301b200d8e > div:nth-child(1) > ul:nth-child(19) > li:nth-child(1) > a:nth-child(1)', '#otnotice-section-e043a136-9048-46f3-9972-30301b200d8e > div:nth-child(1) > ul:nth-child(20) > li:nth-child(1) > a:nth-child(1)',
    '#otnotice-section-e043a136-9048-46f3-9972-30301b200d8e > div:nth-child(1) > ul:nth-child(21) > li:nth-child(1) > a:nth-child(1)', '#otnotice-section-e043a136-9048-46f3-9972-30301b200d8e > div:nth-child(1) > ul:nth-child(22) > li:nth-child(1) > a:nth-child(1)',
    '#otnotice-section-e043a136-9048-46f3-9972-30301b200d8e > div:nth-child(1) > ul:nth-child(23) > li:nth-child(1) > a:nth-child(1)'
]

cgl_scraper(platform=platform, locator=locator, click_button=True, locator3=locator3)


#### Threads

platform = comguide_links[comguide_links['name'] == 'Threads']
locator = '.x1xzm06s > div:nth-child(1) > span:nth-child(1)'

cgl_scraper(platform=platform, locator=locator)


#### Hatenablog

platform = comguide_links[comguide_links['name'] == 'Hatenablog']
locator = '.entry-content'
locator4= 'section'

additional_link = 'https://policies.hatena.ne.jp/community-guideline'
locator2 = '.policies-content'

scrape_multiple(platform=platform, locator1=locator, locator2=locator2, text_scrambled=True,
                locator4=locator4, additional_link=additional_link)


#### Hatenablog

platform = pd.DataFrame([['Hatenablog', 'https://help-en.hatenablog.com/entry/guideline']],
                        columns=['name', 'comguide'])
locator = 'div.entry-content:nth-child(2)'

cgl_scraper(platform=platform, locator=locator, name_arg='_en')


#### Stack exchange

platform = comguide_links[comguide_links['name'] == 'Stack Exchange']
locator = 'main.d-flex'

additional_links = [
    'https://stackoverflow.com/conduct',
    'https://stackoverflow.com/conduct/abusive-behavior',
    'https://stackoverflow.com/conduct/sensitive-content',
    'https://stackoverflow.com/conduct/political-speech',
    'https://stackoverflow.com/conduct/misleading-information',
    'https://stackoverflow.com/conduct/inauthentic-usage'
]

locator2 = 'div.wmx9:nth-child(3)' # unacceptable behavior only
# locator4 = '#content' # including intro, our expectations, and reporting as well
locator3 = '.w90' # input as alternative locator (should by now work mostly automatised)

scrape_multiple(platform=platform, locator1=locator, locator2=locator2, alt_locator=locator3,
                additional_link=additional_links)


#### Douban

platform = comguide_links[comguide_links['name'] == 'Douban']
locator = '.article'

cgl_scraper(platform=platform, locator=locator)


#### 9gag

platform = comguide_links[comguide_links['name'] == '9gag']
locator = '.section-faqs'
additional_links = [
    'https://9gag.helpshift.com/hc/en/3-9gag/faq/19-a-few-rules-to-keep-9gag-safe-and-fun-for-everyone/',
    'https://9gag.helpshift.com/hc/en/3-9gag/faq/20-no-pornography/',
    'https://9gag.helpshift.com/hc/en/3-9gag/faq/21-no-violence-gory-and-harmful-content/',
    'https://9gag.helpshift.com/hc/en/3-9gag/faq/22-no-hate-speech-and-bullying/',
    'https://9gag.helpshift.com/hc/en/3-9gag/faq/23-no-spamming-manipulation-and-multiple-account-abuse/',
    'https://9gag.helpshift.com/hc/en/3-9gag/faq/24-no-deceptive-content/',
    'https://9gag.helpshift.com/hc/en/3-9gag/faq/25-no-personal-and-confidential-information/',
    'https://9gag.helpshift.com/hc/en/3-9gag/faq/26-no-illegal-activities/',
    'https://9gag.helpshift.com/hc/en/3-9gag/faq/27-no-impersonation/',
    'https://9gag.helpshift.com/hc/en/3-9gag/faq/28-no-copyright-and-trademark-infringement/',
    'https://9gag.helpshift.com/hc/en/3-9gag/faq/29-enforcement/'
]

locator2 = '.faq-details'

scrape_multiple(platform=platform, locator1=locator, locator2=locator2, additional_link=additional_links)


#### patreon

platform = comguide_links[comguide_links['name'] == 'Patreon']
locator = '#main-content'
locator4 = [
    'div.sc-fc3e0d65-0:nth-child(1) > div:nth-child(1)',
    '.sc-d817a340-1 > div:nth-child(2)'
]

cgl_scraper(platform=platform, locator=locator, text_scrambled=True, locator4=locator4)


#### DeviantArt

platform = comguide_links[comguide_links['name'] == 'DeviantArt']
locator = '._2wle9'

cgl_scraper(platform=platform, locator=locator)


#### Kakao

platform = comguide_links[comguide_links['name'] == 'Kakao']
locator = '.wrap_terms'

additional_link = 'https://www.kakaocorp.com/page/responsible/detail/hateSpeech'
locator2 = '.wrap_rules'

scrape_multiple(platform=platform, locator1=locator, locator2=locator2, additional_link=additional_link)


#### Kakao (English translation)

platform = pd.DataFrame([['Kakao', 'https://www.kakao.com/policy/oppolicy?lang=en']],
                        columns=['name', 'comguide'])
locator = '.wrap_terms'

cgl_scraper(platform=platform, locator=locator, ignore_existing=True, name_arg='_en')


#### Sound Cloud

platform = comguide_links[comguide_links['name'] == 'Sound Cloud']
locator = 'body'

cgl_scraper(platform=platform, locator=locator)


#### Imgur

platform = comguide_links[comguide_links['name'] == 'Imgur']
locator = '#rules-container'
locator3 = '.rules-more'

cgl_scraper(platform=platform, locator=locator, locator3=locator3, click_button=True)


#### Wattpad

platform = comguide_links[comguide_links['name'] == 'Wattpad']
locator = '.col-md-8'

res = cgl_scraper(platform=platform, locator=locator, return_value=True)
if res:
    cgl_text0, markdown0, meta0 = res

    # manual text cleaning
    # Inserting a white space after every 'Back to top'
    cgl_text1 = cgl_text0.replace('Back to top', 'Back to top \n')
    markdown1 = markdown0.replace('Back to top', 'Back to top \n')

    save_local(name=platform['name'].iloc[0], cgl_text=cgl_text1, markdown=markdown1)


#### Xiaohongshu
# - case specific solution (done in a rush - could be adapted in function): case: using differing locator strategies for main and additional page (otherwise won't return markdown)

platform = comguide_links[comguide_links['name'] == 'Xiaohongshu']
name = platform['name'].iloc[0]
directory_name = os.path.join(destination_path, name)
if os.path.exists(directory_name):
    logging.info('Guidelines of %s already done, skipping', name)

else:
    url = platform['comguide'].iloc[0]
    logging.info('Scraping guidelines of %s: %s', name, url)

    locator = '#zzxy-content'
    additional_link = 'https://www.xiaohongshu.com/crown/community/agreement?fullscreen=true'
    locator2 = '.container-mode'
    platform2 = pd.DataFrame([[name, additional_link]], columns=['name', 'comguide'])

    gl_text_all = ''
    markdown_all = ''

    driver = webdriver.Firefox(firefox_options)
    driver.get(url)

    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.CSS_SELECTOR, '#zzxy-content > h1:nth-child(1)')))

    page_source0 = driver.page_source

    overall_elem = driver.find_element(By.CSS_SELECTOR, '#zzxy-content')
    gl_text0 = overall_elem.get_attribute('textContent')
    inner_html0 = overall_elem.get_attribute('innerHTML')
    markdown0 = markdownify.markdownify(inner_html0, strip=['a', 'img'])

    current_time = datetime.now()
    formatted_time = current_time.strftime('%Y-%m-%d %H:%M:%S')
    meta0 = {'name': name,
             'url': url,
             'timestamp': formatted_time,
             'locator': locator}

    save_local(name=name, metadata=meta0, html_source=page_source0,
               inner_html=inner_html0, cgl_text=gl_text0, markdown=markdown0, name_arg='_1')

    driver.quit()

    # additional link
    gl_text1, markdown1, meta1 = cgl_scraper(platform=platform2, locator=locator2,
                                             name_arg='_2', return_value=True, ignore_existing=True)
    gl_text_all = gl_text0 + gl_text1
    markdown_text_all = markdown0 + markdown1
    meta_all = [meta0, meta1]

    save_local(name=name, metadata=meta_all, cgl_text=gl_text_all, markdown=markdown_text_all)


    #### Xiaohongshu (translation)

    platform = pd.DataFrame([['Xiaohongshu', 'https://www.xiaohongshu.com/en/community_guidelines']],
                            columns=['name', 'comguide'])
    locator = '.main-pattern'

    cgl_scraper(platform=platform, locator=locator, name_arg='_en', ignore_existing=True)

    with open(os.path.join(directory_name, 'Xiaohongshu_cgl_source_en.html'),
              encoding='UTF-8') as file:
        html_raw = file.read()
    md = markdownify.markdownify(html_raw, strip=['a', 'img'])

    save_local(name='Xiaohongshu', markdown=md, name_arg='_en')


#### Steam Community

platform = comguide_links[comguide_links['name'] == 'Steam Community']
locator = '#ssa_box'
additional_link = 'https://help.steampowered.com/en/faqs/view/6862-8119-C23E-EA7B'
locator2 = '._2PQsW53YUsH-Z6TICGEF3K'

scrape_multiple(platform=platform, locator1=locator, locator2=locator2, additional_link=additional_link)


#### Medium

platform = comguide_links[comguide_links['name'] == 'Medium']
locator = '.fu > article:nth-child(2) > div:nth-child(1) > div:nth-child(1) > section:nth-child(2) > div:nth-child(1)' # old: '.ft > article:nth-child(2) > div:nth-child(1) > div:nth-child(1) > section:nth-child(2) > div:nth-child(1)'

additional_links = [
    'https://help.medium.com/hc/en-us/articles/360039513913-About-the-No-Duplicate-Content-rule',
    'https://policy.medium.com/medium-username-policy-7054a77fb04f'
]
locator2 =  '.lt-article'
alt_locator = '.gn > div:nth-child(1) > div:nth-child(1)' # input as alternative locator

scrape_multiple(platform=platform, locator1=locator, locator2=locator2, alt_locator=alt_locator,
                additional_link=additional_links)


#### Nicovideo

platform = comguide_links[comguide_links['name'] == 'Nicovideo']
locator = '.wrapper'

cgl_scraper(platform=platform, locator=locator)


#### Ameblo

platform = comguide_links[comguide_links['name'] == 'Ameblo']
locator = '.entry__body'

cgl_scraper(platform=platform, locator=locator)


#### TradingView

platform = comguide_links[comguide_links['name'] == 'TradingView']
locator = '.tv-promo-page-layout'

cgl_scraper(platform=platform, locator=locator)


#### Douyin

platform = comguide_links[comguide_links['name'] == 'Douyin']
locator = '.addaf7908249c186268807f149aa9f73-scss'

cgl_scraper(platform=platform, locator=locator)


#### Zhihu

# ---> Established new bot-detection (can't enter the page automated with Selenium anymore)
#
# Requires new approach: First remove banner
# Problem in text: Read more button does not automatically expand text, but opens a banner to login/register to read the whole text.

platform = comguide_links[comguide_links['name'] == 'Zhihu']

name = platform['name'].iloc[0]
directory_name = os.path.join(destination_path, name)
if os.path.exists(directory_name):
    logging.info('Guidelines of %s already done, skipping', name)

else:
    logging.info('Processing manually downloaded guidelines of %s', name)
    locator = 'div.RichText:nth-child(2)'
    locator3 = '.Modal-closeButton' # log in banner at the beginning of the page
    #locator_readmore = '.ContentItem-expandButton'

    # cgl_scraper(platform=platform, locator=locator, click_button=True, locator3=locator3)

    # manual approach using the copy-pasted inner_html due to autmatic browser detection:

    with open(os.path.join(directory_name, 'Zhihu_cgl_source.html'),
              'r', encoding='utf-8') as file:
        inner_html = file.read()

    markdown_text = markdownify.markdownify(inner_html, strip=['a', 'img'])

    soup = BeautifulSoup(inner_html, 'html.parser')
    gl_text = soup.get_text()

    current_time = datetime.now()
    formatted_time = current_time.strftime('%Y-%m-%d %H:%M:%S')

    meta = {'name': platform['name'].iloc[0],
            'url': platform['comguide'].iloc[0],
            'timestamp': formatted_time,
            'locator': None}

    save_local(name=platform['name'].iloc[0], markdown=markdown_text,
               cgl_text=gl_text, metadata=meta, inner_html=inner_html)

    with open(os.path.join(directory_name, 'Zhihu_page_source.html'),
              'r', encoding='utf-8') as file:
        html_source = file.read()

    # Parse the HTML
    full_soup = BeautifulSoup(html_source, 'html.parser')

    # Find the specific element by its tag, id, class, etc.
    # Example: Find element by id
    inner_element = full_soup.find('div', class_='RichText ztext Post-RichText css-1ygg4xu')
    inner_html = inner_element.decode_contents()  # Returns the inner HTML

    # retrieve text & markdown from inner_html
    gl_text = inner_element.get_text()
    markdown_text = markdownify.markdownify(inner_html, strip=['a', 'img'])

    # save inner_html, text and markdown
    save_local(name=platform['name'].iloc[0], markdown=markdown_text,
               cgl_text=gl_text, inner_html=inner_html)


#### Discord
#
# Case-specific solution: The additional links guiding to the policy explainers hold expandable boxes which require a button click, when one box is expanded the other is closed, so that to retrive the full text and markdown each individual paragraph (stored in div tags) needs to be located one by one, for the expanded version of all boxes to be captured.
#
# - https://support.discord.com/hc/en-us/articles/4410339349655-Discord-s-Copyright-IP-Policy
#   (to be included?)

platform = comguide_links[comguide_links['name'] == 'Discord']
name = platform['name'].iloc[0]
directory_name = os.path.join(destination_path, name)
if os.path.exists(directory_name):
    logging.info('Guidelines of %s already done, skipping', name)

else:
    logging.info('Scraping guidelines of %s', name)

    locator = 'div.container780:nth-child(2)'

    additional_links = [
        'https://discord.com/safety/bullying-harassment-threats-policy-explainer',
        'https://discord.com/safety/doxxing-policy-explainer',
        'https://discord.com/safety/hateful-conduct-policy-explainer',
        'https://discord.com/safety/violent-extremism-policy-explainer',
        'https://discord.com/safety/violence-graphic-content-policy-explainer',
        'https://discord.com/safety/child-safety-policy-explainer', # 3 expandables
        'https://discord.com/safety/sexual-content-policy-explainer',
        'https://discord.com/safety/non-consensual-intimate-media-policy-explainer',
        'https://discord.com/safety/suicide-self-harm-policy-explainer',
        'https://discord.com/safety/platform-manipulation-policy-explainer',
        'https://discord.com/safety/misinformation-policy-explainer',
        'https://discord.com/safety/identity-authenticity-policy-explainer',
        'https://discord.com/safety/deceptive-practices-policy-explainer',
        'https://discord.com/safety/copyright-trademark-policy-explainer',
        # 'https://support.discord.com/hc/en-us/articles/4410339349655-Discord-s-Copyright-IP-Policy', # different look
        'https://discord.com/safety/dangerous-regulated-goods-policy-explainer',
        'https://discord.com/safety/gambling-policy-explainer',
        'https://discord.com/safety/human-trafficking-policy-explainer',
        'https://discord.com/safety/sexual-solicitation-policy-explainer'
    ]

    locator2 = '.rich-content-left' # content locator additional links
    # locators to expand text in content
    button_locator1 = '#w-dropdown-toggle-1 > img:nth-child(2)'
    button_locator2 = '#w-dropdown-toggle-2 > img:nth-child(2)'
    button_locator3 = '#w-dropdown-toggle-3 > img:nth-child(2)'
    locator3 = [button_locator1, button_locator2, button_locator3]

    # Getting initial platform:
    discord_strip_tags_markdown = ['a', 'img']
    gl_text0, markdown0, meta0 = cgl_scraper(platform=platform, locator=locator,
                                             return_value=True, name_arg='_0',
                                             md_strip=discord_strip_tags_markdown,
                                             ignore_existing=True)

    # Procedure for additional links:
    name = platform['name'].iloc[0]
    for name_arg, link in enumerate(additional_links):
        gl_text = ''
        markdown_text = ''

        driver = webdriver.Firefox(firefox_options)
        driver.get(link)
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, locator2)))
        pg_source = driver.page_source
        html_soup = pg_source # BeautifulSoup(pg_source, 'html.parser')

        # iterating over all divs in locator2
        overall_elem = driver.find_element(By.CSS_SELECTOR, locator2)
        elems = overall_elem.find_elements(By.TAG_NAME, 'div')

        # iterate over all divs in locator2
        button_n = 0
        div_text_prev = ''
        for elem in elems:
            # getting on lowest div level to not retrive dublicate text:
            while True:  # Keep going deeper until no more divs are found inside
                try:
                    elem = elem.find_element(By.TAG_NAME, 'div')
                except:  # No more divs inside the current div
                    break
            # try to expand text if present:
            try:
                button = elem.find_element(By.CSS_SELECTOR, locator3[button_n])
                button.click()
                button_n += 1
            except:
                pass
            # save text and markdown of divs with expanded text (if expandable):
            div_text = elem.get_attribute('textContent')
            if div_text != div_text_prev:
                gl_text += elem.get_attribute('textContent')
                inner_html = elem.get_attribute('innerHTML')
                inner_soup = inner_html # BeautifulSoup(inner_html, 'html.parser')
                markdown_text += markdownify.markdownify(inner_soup, strip=discord_strip_tags_markdown)

                div_text_prev = div_text

        current_url = driver.current_url
        current_time = datetime.now()
        formatted_time = current_time.strftime('%Y-%m-%d %H:%M:%S')
        meta = {'name': name,
                'url': current_url,
                'timestamp': formatted_time,
                'locator': locator}

        save_local(name=name, name_arg='_'+str(name_arg+1),
                   html_source=html_soup, inner_html=inner_soup,
                   cgl_text=gl_text, markdown=markdown_text, metadata=meta)

        driver.quit()

        # combining all texts, metadata and markdown:
        # Note: add a paragraph separator because individual pages are usually sections but, at least, paragraphs
        gl_text0 += '\n\n' + gl_text
        markdown0 += '\n\n' + markdown_text
        if isinstance(meta0, list):
            meta0.append(meta)
        else:
            meta0 = [meta0, meta]

    save_local(name=name, metadata=meta0, cgl_text=gl_text0, markdown=markdown0)


#### Bilibili

platform = pd.DataFrame([['Bilibili', 'https://www.bilibili.com/blackboard/manga/activity-OS6gNk0mmB.html']],
                        columns=['name', 'comguide'])
name = platform['name'].iloc[0]
directory_name = os.path.join(destination_path, name)
if os.path.exists(directory_name):
    logging.info('Guidelines of %s already done, skipping', name)

else:
    logging.info('Scraping guidelines of %s', name)

    locator = '.t-space-container'

    cgl_scraper(platform=platform, locator=locator, ignore_existing=True)


    #### Bilibili (translation)

    platform = pd.DataFrame([['Bilibili', 'https://www.bilibili.tv/marketing/protocal/communityrules_en.html']],
                            columns=['name', 'comguide'])
    locator = '.t-space-container'

    cgl_scraper(platform=platform, locator=locator, name_arg='_en', ignore_existing=True)

    with open(os.path.join(directory_name, 'Bilibili_cgl_source_en.html'), encoding='UTF-8') as file:
        html_raw = file.read()
    md = markdownify.markdownify(html_raw, strip=['a', 'img'])

    save_local(name='Bilibili', markdown=md, name_arg='_en')



#### Patriots.win

platform = comguide_links[comguide_links['name'] == 'Patriots.win']
locator = '.sc-1o7adtx-8 > blockquote:nth-child(4)'

cgl_scraper(platform=platform, locator=locator)


#### Mastodon

platform = comguide_links[comguide_links['name'] == 'Mastodon']
locator = 'div.about__section:nth-child(4)'
locator3 = 'div.about__section:nth-child(4) > div:nth-child(1) > svg:nth-child(1)'

cgl_scraper(platform=platform, locator=locator, locator3=locator3, click_button=True)


#### Blind

platform = comguide_links[comguide_links['name'] == 'Blind']
locator = 'div.bg-white:nth-child(2) > div:nth-child(1)'

cgl_scraper(platform=platform, locator=locator)


#### nnmclub

platform = comguide_links[comguide_links['name'] == 'Nnmclub']
locator = 'div.postbody'

cgl_scraper(platform=platform, locator=locator)


#### Gab
# (ToS not CGL)
#platform = pd.DataFrame([['Gab', 'https://gab.com/about/tos']], columns=['name', 'comguide'])
#locator = '.pwK6B > div:nth-child(1)'
#cgl_scraper(platform=platform, locator=locator)

