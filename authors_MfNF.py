import mediawiki_api as db
import requests
import datetime
import dateutil.parser 
import os.path
import pymysql
import json

config = json.load(open("config.json", "r"))
topics = config["topics"]

def connect():
  """ Returns the MySQLdb connection object """
  return pymysql.connect(
    host = config["db"]["host"],
    user = config["db"]["user"],
    passwd = config["db"]["password"],
    db = config["db"]["database"])


def sql_wrapper(statement):
	try:
		connection = connect()
		with connection.cursor() as cur:
				cur.execute(statement)
				connection.commit()
	except:
		print("Error with statement: %s"%statement)
	finally:
		connection.close()



#author_name as string, date as pandas datetime

#date types, sql import in conda

def actualize_cell_value(author_name, topic, date):
	try:
		connection = connect()
		with connection.cursor() as cur:
				cur.execute("""INSERT INTO MFNF_EDITS (date, name, topic, number_of_edits) VALUES (%s, %s, %s, 1) ON DUPLICATE KEY UPDATE number_of_edits = number_of_edits +1""", (date, author_name, topic))
				connection.commit()
	except:
		print("Error in actualizing cell_value for cell (%s, %s, %s)"%(date, author_name, topic))
	finally:
		connection.close()


def table_exists():
	q = f"""SELECT * 
			FROM information_schema.tables
			WHERE table_schema = '{config["db"]["database"]}' 
    			AND table_name = 'MFNF_EDITS'
			LIMIT 1"""

	try:
		cnx = connect()
		with cnx.cursor() as cur:
			cur.execute(q)
			res = cur.fetchall()
			if res:
				return True
			else:
				return False
	except:
		print("Checking if table MFNF_EDITS exists failed")
	finally:
		cnx.close()



#Returns Insert-Statement for actualization
def actualize(topics, request_session=None):
	if request_session is None:
		request_session = requests.Session()

	sitemap_pages = db.scrape_sitemap(request_session, *topics)

	if os.path.isfile("retrieval_date.txt"):
		with open("retrieval_date.txt","a") as file:
			last_date = file.read()
	else:
		last_date = None

	actualization_list = []

	for topic in topics:
		if last_date is None:
			print("Generating author-frame for topic: %s"%topic)
		else:
			print("Actualizing topic %s"%topic)
		for page in sitemap_pages[topic]:
			for edit in db.get_article_revisions(page, request_session, start_date=last_date):
				actualization_list.append(str((str(dateutil.parser.parse(edit["timestamp"]).date()),edit["user"], topic,"1")))

	with open("retrieval_date.txt", "w+") as file:
		file.write(str(datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"))) #Mediawiki assumes utc-timezone

	return "INSERT INTO MFNF_EDITS (date, name, topic, number_of_edits) VALUES {} ON DUPLICATE KEY UPDATE number_of_edits = number_of_edits +1".format(', '.join(actualization_list))

def main ():
	if not table_exists():
		q = """CREATE TABLE MFNF_EDITS (
				id INT(11) NOT NULL AUTO_INCREMENT,
				date DATE,
				name CHAR(255),
				topic CHAR(255),
				number_of_edits INT(11),
				PRIMARY KEY ( id ),
				UNIQUE (date, name, topic)
			)"""
		try:
			cnx = connect()
			with cnx.cursor() as cur:
				cur.execute(q)
		except:
			print("Creating table MFNF_EDITS exists failed")
		finally:
			cnx.close()
		
	sql_wrapper(actualize(topics))



if __name__ == "__main__":
	main()

	
	