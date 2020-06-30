import urllib.request
import requests
from datetime import date
import pandas as pd
import os
import json

def get_section_id(request_session, topic):
	#in try-catch
	PARAMS = {
	"action": "parse",
	"page": "Mathe_für_Nicht-Freaks:_Sitemap",
	"prop": "sections",
	"format": "json"
	}

	R = request_session.get(url="https://de.wikibooks.org/w/api.php", params=PARAMS)
	data = R.json()

	section_id = {}

	for section in data["parse"]["sections"]:
		if section["line"]==topic:
			return section["index"]

#Speichert die Sitemaps der einzelnen Fächer in einem eigenen doc
def scrape_sitemap_topic(request_session, section_id):
	PARAMS = {
		"action": "parse",
		"page": "Mathe_für_Nicht-Freaks:_Sitemap",
		"section": str(section_id),
		"prop": "links",
		"format": "json"
	}

	R = request_session.get(url="https://de.wikibooks.org/w/api.php", params=PARAMS)
	data = R.json()
	return [link["*"] for link in data["parse"]["links"] if link["ns"]==0 and "exists" in link.keys()]


def scrape_sitemap(request_session, *topics):
	section_ids = {topic: get_section_id(request_session, topic) for topic in topics}
	topic_links = {}
	for topic, id in section_ids.items():
		topic_links[topic] = scrape_sitemap_topic(request_session, id)
	return topic_links

#topic_links as dict
def save_whole_sitemap(topic_links):
	os.makedirs("sitemap", exist_ok=True)
	for topic, links in topic_links.items():
		with open("sitemap/"+topic.replace(" ", "_")+".txt", "w+") as file:
			for link in links:
				file.write("%s\n" % link)

#standart: end_date=today, start_date=last_retrieved_date, options: dict
#check for errors
def get_article_revisions(title, request_session, options= None, start_date=None, end_date=None):
	if options is None:
		options = dict()
	if end_date is None:
		end_date = date.today()

	if start_date is None:
		PARAMS = {
			"action": "query",
			"prop": "revisions",
			"titles": title,
			"rvlimit": "max",
			"rvprop": "timestamp|user",
			"rvdir": "newer",
			"rvend": str(pd.to_datetime(end_date)),
			"rvslots": "main",
			"formatversion": "2",
			"format": "json",
			**options
		}
	else:
		PARAMS = {
			"action": "query",
			"prop": "revisions",
			"titles": title,
			"rvlimit": "max",
			"rvprop": "timestamp|user",
			"rvdir": "newer",
			"rvstart": str(pd.to_datetime(start_date)),
			"rvend": str(pd.to_datetime(end_date)),
			"rvslots": "main",
			"formatversion": "2",
			"format": "json",
			**options
			}

	R = request_session.get(url="https://de.wikibooks.org/w/api.php", params=PARAMS)
	data = R.json()
	if "error" in data.keys():
		print("\033[91m Failed to generate history for article %s \033[0m"%title)
	if "continue" in data.keys():
		#important if limit of 500 edits is reached
		options["rvcontinue"] = data["continue"]["rvcontinue"]
		return data["query"]["pages"][0]["revisions"] + get_article_revisions(title, request_session, options)
	else:
		if "revisions" in data["query"]["pages"][0].keys():
			print("\033[92m History successfully generated for article %s \033[0m"%title)
			return data["query"]["pages"][0]["revisions"]
		else:
			print("\033[94m History successfully generated for article %s - no new edits\033[0m"%title)
			return []


def build_revision_db(request_session, *topics):
	os.makedirs("revisions", exist_ok=True)
	topic_links = scrape_sitemap(request_session, *topics)
	for topic, links in topic_links.items():
		with open("revisions/"+topic.replace(" ", "_")+".txt", "w+") as file:
			for link in links:
				json.dump(get_article_revisions(link, request_session), file)
				file.write("\n")



def main():
	topics = ["Grundlagen der Mathematik", "Analysis 1", "Lineare Algebra","Maßtheorie","Real Analysis",] #, ["Buchanfänge", "sitemap_files/buch_sitemap.html", "index_files/buch_index.txt"], ["Mitmachen für (Nicht-)Freaks", "sitemap_files/mitm_sitemap.html", "index_files/mitm_index.txt"]
	S = requests.Session()
	topic_links = scrape_sitemap(S, *topics)




if __name__ == "__main__":
	S = requests.Session()
	print(get_article_revisions("Mathe_für_Nicht-Freaks:_Sitemap", S, end_date="2020-05-14"))
	#main()