import database as db
import urllib.request
from datetime import date
from datetime import timedelta
import pandas as pd
import os
import functools
import requests
from docx import Document


def get_author_frame_article(revision_json, author_frame):
	for edit in revision_json:
		actualize_cell_value(edit["user"], pd.to_datetime(edit["timestamp"]).normalize().tz_localize(tz=None), author_frame)
				

#author_name as string, date as pandas datetime
def actualize_cell_value(author_name, date, author_frame):
	if author_name not in author_frame:
		author_frame[author_name] = 0
		author_frame.loc[date, author_name] = 1
	else: 
		if date in author_frame.index:
			if pd.notna(author_frame.loc[date, author_name]):
				author_frame.loc[date, author_name] = author_frame.loc[date, author_name] + 1
			else:
				author_frame.loc[date, author_name] = 1
		else:
			author_frame.loc[date, author_name] = 1
	return author_frame

#limit_date as python datetime
def init_author_frame(topic, request_session=None):
	today = pd.to_datetime(date.today())
	author_frame = pd.DataFrame([today], columns=['date'])
	author_frame['date'] = pd.to_datetime(author_frame['date'])
	author_frame = author_frame.set_index('date')

	if request_session is None:
		request_session = requests.Session()

	sitemap_pages = db.scrape_sitemap(request_session, topic)[topic]
	print("Generating author-frame for topic: %s"%topic)

	for page in sitemap_pages:
		get_author_frame_article(db.get_article_revisions(page, request_session), author_frame)

	return author_frame.fillna(0)


def create_from_zero(*topics, request_session=None):
	if request_session is None:
		request_session = requests.Session()

	topic_frames = {topic: init_author_frame(topic, request_session=request_session) for topic in topics}

	mfnf_frame = functools.reduce(lambda a,b: a.add(b, fill_value=0), topic_frames.values())

	os.makedirs("topic_frames", exist_ok=True)

	for topic, frame in topic_frames.items():
		write_author_frame(frame, "topic_frames/"+topic.replace(" ", "_")+".csv")

	write_author_frame(mfnf_frame, "topic_frames/author_frame.csv")

	return topic_frames, mfnf_frame

def create_mfnf_frame(topic_frames):
	return functools.reduce(lambda a,b: a.add(b, fill_value=0), topic_frames.values())

def delete_up_to_date(topic_frame, date):
	while topic_frame.index.max()>=pd.to_datetime(date):
		topic_frame.drop(pd.to_datetime(date), inplace=True)

#Annahme topic_frames auf selben zeitlichen Stand wie mfnf frame
def actualize_author_frames(topic_frames, mfnf_frame=None, request_session=None):
	if request_session is None:
		request_session = requests.Session()

	sitemap_pages = db.scrape_sitemap(request_session, *(topic_frames.keys()))

	for topic in topic_frames.keys():
		topic_frames[topic].sort_index(inplace=True)

	last_date = min([topic_frames[topic].index.max() for topic in topic_frames.keys()])

	for topic in topic_frames.keys():
		topic_frames[topic].sort_index(inplace=True)
		delete_up_to_date(topic_frames[topic], last_date)

	if mfnf_frame is not None:
		mfnf_frame.sort_index(inplace=True)
		delete_up_to_date(mfnf_frame, last_date)

	for topic in topic_frames.keys():
		print("Actualizing topic %s"%topic)

		for page in sitemap_pages[topic]:
			revisions = db.get_article_revisions(page, request_session, start_date=last_date)
			if revisions:
				get_author_frame_article(revisions, topic_frames[topic]) 
				if mfnf_frame is not None:
					get_author_frame_article(revisions, mfnf_frame)


def write_author_frame(author_frame, filename):
	author_frame.to_csv(filename, mode="w+")

def write(topic_frames, mfnf=None):
	os.makedirs("topic_frames", exist_ok=True)
	for topic in topic_frames.keys():	
		write_author_frame(topic_frames[topic], "topic_frames/"+topic.replace(" ", "_")+".csv")
	if mfnf is not None:
		write_author_frame(mfnf, "topic_frames/author_frame.csv")


def import_author_frame(filename="topic_frames/author_frame.csv"):
	df = pd.read_csv(filename, na_values=[" "], parse_dates=["date"], index_col="date")
	return df

def read(*topics, mfnf_frame=True):
	existing=[]
	topic_frames = {}
	for topic in topics:
		if not os.path.isfile("topic_frames/"+topic.replace(" ", "_")+".csv"):
			topic_frames[topic] = init_author_frame(topic)
			write_author_frame(topic_frames[topic], "topic_frames/"+topic.replace(" ", "_")+".csv")
		else:
			existing.append(topic)
	if existing:
		for topic in existing:
			topic_frames[topic] = import_author_frame("topic_frames/"+topic.replace(" ", "_")+".csv")

	if mfnf_frame:
		mfnf_frame = import_author_frame("topic_frames/author_frame.csv")
		return topic_frames, mfnf_frame
	else:
		return topic_frames

def create_accumulation(topic_frame, days=90):
	#topic_frame.sort_index(inplace=True)
	topic_frame.index = pd.DatetimeIndex(topic_frame.index)
	index = pd.date_range(topic_frame.index.min(), pd.to_datetime(date.today()))
	topic_frame = topic_frame.reindex(index, fill_value=0)
	return topic_frame.rolling(min_periods=1, window=days).sum()


def get_authors(accumulated_frame, edits, datum=date.today()):
	authors = list(accumulated_frame.columns[accumulated_frame.loc[pd.to_datetime(datum)]>edits])
	edits = list(accumulated_frame[authors].loc[pd.to_datetime(datum)])
	author_dict =  dict(sorted(list(zip(authors,edits)), key=lambda x: x[1], reverse=True))  
	if "authors" in author_dict.keys():
		del author_dict["authors"]
	if "active authors" in author_dict.keys():
		del author_dict["active authors"]
	return author_dict



if __name__ == "__main__":
	topics = ["Grundlagen der Mathematik", "Analysis 1", "Lineare Algebra 1","Maßtheorie","Real Analysis", "Mitmachen für (Nicht-)Freaks"] #, ["Buchanfänge", "sitemap_files/buch_sitemap.html", "index_files/buch_index.txt"], ["Mitmachen für (Nicht-)Freaks", "sitemap_files/mitm_sitemap.html", "index_files/mitm_index.txt"]
	S = requests.Session()

	if not os.path.isdir("topic_frames"):
		topic_frames, mfnf = create_from_zero(*topics)
	else:
		topic_frames, mfnf = read(*topics)
		actualize_author_frames(topic_frames, mfnf)
		write(topic_frames, mfnf)
	
	limit_date = pd.to_datetime(date.today()-timedelta(days=365))
	mfnf = mfnf[mfnf.index>limit_date]
	accumulation  = create_accumulation(mfnf)
