# COMPARE (Content Moderation Policies and Reports) - Dataset

This repository consists of three parts. We make available a dataset combining general information about 132 platforms with six links to websites where platforms report on different content moderation aspects [here](./data/COMPARE.csv).
Moreover, we provide the text of [76 community guidelines](./data/community-guidelines). For more information please refer to our [ICWSM paper](INSERT LINK).

In the folder [src](./src/) you can find the scripts which were used to scrape and translate the community guidelines.
If you want to use our data, we kindly ask you to reference the corresponding paper.

**Recommended Citation**: Nahrgang, M.; Weidmann, N. B.; Quint, F.; Nagel, S.; Theocharis, Y.; & Roberts, M. E. (forthcoming). Written for Lawyers or Users? Mapping the Complexity of Community Guidelines. Proceedings of the International AAAI Conference on Web and Social Media.


### 1. Platform Information 

For each platform, we collected information about the country, the size, the age, and the type of the platforms as well as whether they are decentralized or considered as alt-tech platforms.

To identify larger platforms, we started with an initial list of major social media platforms by combining the most popular social media platforms from ten global and regional (U.S., China, Germany) rankings. From this candidate list, we then selected those platforms for inclusion in the dataset if they fit our definition of “social media platforms,” namely if they (i) host user-generated content that is (ii) at least to some extent public-facing and in principle visible to anyone upon registration and (iii) that stays consistently accessible over a longer period.

| **Variable**       | **Definition** |
|--------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Country (countrycode)     | We coded the platform country based on the country of the platform’s headquarters. To retrieve this information, we consulted the platforms’ self-descriptions on their website (About sections) or their LinkedIn accounts. Additionally, we used sources like Crunchbase and Wikipedia. This information is procided with ISO Alpha-3 codes for the countries. |
| Platform Size (monvisit)  | To determine the platforms’ size, we relied on the marketing portal Similarweb’s monthly visit estimates (Similarweb 2024). We collected the estimates in February 2024. |
| Platform Age (year)       | We collected the year a platform was launched to determine its age. The search strategy for platform age was similar to the one used for determining the country. |
| Platform Type (type)      | We employ a platform typology inspired by Rajendra-Nicolucci and Zuckerman (2021). Unlike their approach, we streamlined the categories into four distinct types. We adapted the definitions as follows: <br> **1. Chat platforms**: revolve around private either one-on-one or small-group communication. <br> **2. Creator platforms**: “enable users to share a specific type of media (like video, live streams, blogs, or art), in a one-to-many fashion. They are home to ‘creators,’ people who consistently make content for the platform, often as a source of income, and to audiences who turn to these platforms for entertainment, information, and a sense of identity and community in fandom” (Rajendra-Nicolucci and Zuckerman 2021, p. 63). <br> **3. Forum platforms**: are focused on topics of common interest rather than on preexisting social relationships. Forums can be text- or image-based. Forums can follow a question-answer type. Users usually have an anonymous username. <br> **4. Social Network platforms**: are general-purpose platforms that focus on connecting people who either already know each other or are looking for new connections (e.g., professional networking, dating). |
| Decentralized (decentralized)| Decentralized platforms such as Mastodon or Bluesky inherit their name from their decentralized technical setup. Other than mainstream social media platforms, the ownership of their servers is distributed, thus circumventing central governance for example in regard to content moderation. |
| Alt-Tech  (alt-tech)      | Alt-tech (Alternative Technology) platforms such as Gab, frequently used by but not exclusive to the far-right, provide an alternative to Silicon Valley-controlled mainstream platforms and are usually characterized by minimal content moderation and a strong emphasis on promoting protecting free speech rights. |

### 2. Links to Content Moderation Policies

For each platform, COMPARE includes links to six different types of platform policies: (1) the privacy policies, (2) the terms of services, (3) the community guidelines, (4) the transparency reports, (5) and information about a platform’s content moderation enforcement options and (6) how the moderation process is structured. The links were collected in the period between October 2023 to January 2024. 

As we were interested in how transparent platforms themselves are, these links in general refer to statements of the platforms on their websites except if a platform has incorporated the policies of an affiliated company. For example, as YouTube is part of Google, it relies on Google’s privacy policy. Moreover, links could be collected and reused for multiple variables if they contain the corresponding information. For example, platforms might decide to address how they enforce content moderation and how the content moderation process is structured under the same link.


| **Variable**               | **Definition**                                                                                                                                                                    |
|----------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Privacy Policies (privacy) | URL to a platform’s privacy policy or similar document detailing data protection rules.                                                                                          |
| Terms of Services (tos)    | URL to a platform’s terms of service/use or similar document containing legal rules of the platform’s usage.                                                                     |
| Community Guidelines (comguide) | URL to a platform’s community guidelines or similar document describing the rules of behavior for the platform.                                                       |
| Transparency (trarep)      | URL to a platform’s transparency report where the platform reports about the scope of content moderation in a given timeframe.                                                   |
| Enforcement (enfopt)       | URL to a platform’s enforcement options of content moderation. These can be, for example, the removal, downgrading, or labeling of content or users.                           |
| Process (cmpro)            | URL to a platform’s website where the platform describes how the content moderation process is organized, for example, if it relies on automated means, users, or reviewers. |


### 3. Community Guidelines

We also provide the text of community guidelines which are sometimes also referred to as community standards or codes of conduct and the [corresponding collection meta data](./data/community-guidelines-metadata.csv).

Of the 132 platforms in the COMPARE dataset, 92 platforms have published such guidelines. We included 89 community guidelines because Instagram and Threads rely on Facebook’s guidelines and were thus not included again. Moreover, the platform Caffeine went offline before we finalized the scraping.

We collected 76 community guidelines between August 4th and September 16th, 2024 using a computer located in Germany, using the default language settings. This resulted in 54 English and 22 non-English guidelines. We then translated the non-English texts into English using primarily the DeepL API. Because of language availability, we used the Google Cloud Translation API for the two Persian texts. See [here](./src/translations.py) for the translation script and [here](./src/community-guidelines-scraper.py) for the script to download the HTML version of the guidelines and extract the corresponding Markdown version.

The 76 community guidelines can be complemented with 13 community guidelines from the [Platform Governance Archive’s (PGA) GitHub Repository](https://github.com/OpenTermsArchive/pga-versions) (Katzenbach et al., 2023). In order to use guidelines from a comparable timeframe please refer to [the version from August 13, 2024](https://github.com/OpenTermsArchive/pga-versions/tree/c4e6cb868a4b1adc24c457ffb965d24454c89d12), also referenced as Git submodule in the [data/](./data/) directory.


### References

+ Katzenbach, C.; Dergacheva, D.; Fischer, A.; Kopps, A.; Kolesnikov, S.; Redeker, D.; and Viejo Otero, P. 2023a. Platform Governance Archive (PGA) v2.
+ Rajendra-Nicolucci, E. C.; and Zuckerman, E. 2021. An Illustrated Field Guide to Social Media. Knight First Amendment Institute.
