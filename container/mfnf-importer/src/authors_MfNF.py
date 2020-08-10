from collections import defaultdict
from sys import stderr

import mediawiki_api as db
import requests
import datetime
import dateutil.parser 
import json

#Returns Insert-Statement for actualization
def actualize(topics, request_session=None, last_date=None):

	if request_session is None:
		request_session = requests.Session()

	sitemap_pages = db.scrape_sitemap(request_session, *topics)

	actualization_list = []

	for topic in topics:
		if last_date is None:
			print("Generating author-frame for topic: %s"%topic, file=stderr)
		else:
			print("Actualizing topic %s"%topic, file=stderr)
		edit_count = defaultdict(int)
		for page in sitemap_pages[topic]:
			for edit in db.get_article_revisions(page, request_session, start_date=last_date):
				edit_count[(str(dateutil.parser.parse(edit["timestamp"]).date()),edit["user"].replace("'", "`"), topic)] += 1
		for (ts, user, topic), edits in edit_count.items():
			actualization_list.append(str((ts, user, topic, edits)))

	if actualization_list:
		#mysql: 
		#return "INSERT INTO MFNF_EDITS (date, name, topic, number_of_edits) VALUES {} ON DUPLICATE KEY UPDATE number_of_edits = number_of_edits +1".format(', '.join(actualization_list)), str(datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")) #Mediawiki assumes utc-timezone
		
		#postgres: 
		return "INSERT INTO MFNF_EDITS (date, name, topic, number_of_edits) VALUES {} ON CONFLICT (date, name, topic) DO UPDATE SET number_of_edits = MFNF_EDITS.number_of_edits +1;".format(', '.join(actualization_list)), str(datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")) #Mediawiki assumes utc-timezone
	else:
		return "", str(datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
	config = json.load(open("config.json", "r"))

	topics = config["topics"]

	if config.get("last_date", "") != "":
		last_date = config["last_date"]
	else:
		last_date = None

	sql, new_date = actualize(topics, last_date=last_date)

	config["last_date"] = new_date

	json.dump(config, open("config.json", "w+"))

	print(sql)

	
	
