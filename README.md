# MfNF-Collaborator-Numbers
Generates an overview of all collaborators and their edits for the project "Mathe für Nicht-Freaks". This is based on the sitemap: https://de.wikibooks.org/w/index.php?title=Mathe_f%C3%BCr_Nicht-Freaks:_Sitemap#Ma%C3%9Ftheorie

Usage: just run via command-line and python3 or use individual function from the code

Idea:
Via the sitemap we can access all articles from different subjects. There we scrape the editing-history of the pages (download it first in /wiki, because otherwise the code would be too slow) and create a dictionary per topic (or a general one) with {author-name : List of editing-events}. These events have the following form: (article-name, date). With this basis we can filter the dictionary via the date-attribute and get the collaborator-numbers for the last xy days.
