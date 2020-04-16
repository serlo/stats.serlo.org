from bs4 import BeautifulSoup
import urllib.request
from datetime import date
from datetime import timedelta
import time


"""Hilfsfunktionen"""
#Gibt das zweite Element eines Tupels zurück
def get_second(x):
	return x[1]

#Ezeugt einen gültigen Weblink auf die History-Seite eines Artikels
#Input-Beispiel: wiki_link = /wiki/Mathe_f%C3%BCr_Nicht-Freaks:_Permutationen
def get_history_link(wiki_link):
	return "https://de.wikibooks.org/w/index.php?title="+wiki_link[6:]+"&limit=1000&action=history"

#Erzeugt einen gültigen Pfad zum speichern einer html-Datei im Ordner wiki
#Input-Beispiel: wiki_name = /wiki/Mathe_f%C3%BCr_Nicht-Freaks:_Permutationen
def get_storage_place(wiki_name):
	return wiki_name[1:]+".html"

#Erzeugt aus einem gültigen Pfad den Namen eines Artikels
#Input: elem = "wiki/Mathe_f%C3%BCr_Nicht-Freaks:_Was_ist_Algebra%3F.html"
def get_name(elem):
	return elem[:-5]

#Mapt eine Monatsabkürzung auf die richtige Zahl
#Input-Beispiel month_string = "Jan"
def map_month(month_string):
	months = dict([
		("Jan" , 1),
		("Feb" , 2),
		("Mär" , 3),
		("Apr" , 4),
		("Mai" , 5),
		("Jun" , 6),
		("Jul" , 7),
		("Aug" , 8),
		("Sep" , 9),
		("Okt" , 10),
		("Nov" , 11),
		("Dez" , 12)
		])
	return months[month_string]

#Konvertiert einen String zu einem gültigen Datums-Element
#Input-Beispiel: "20:18, 19. Aug. 2018"
def convert_to_date(date_str):
	try: #da die Tageszahl einstellig und/oder zweistellig sein kann
		day = int(date_str[7:9])
		month = map_month(date_str[11:14])
	except:
		day = int(date_str[7:8])
		month = map_month(date_str[10:13])
	return date(int(date_str[-4:]), month,  day)


"""Scraping der Seiten mit Versionsgeschichten"""
"""Aufruf: 
#articles = extract_links("test.html") #liest verlinkte Artikel ein
#links = list(map(get_history_link, articles)) #generiert "echte" Links
#storage_places = list(map(get_storage_place, articles)) #kreiert eine Liste der storage_places
#scrape_db(links, storage_places, "wiki_index.txt") #Scrapt die Webseiten
"""

#Extrahiert alle Links aus einem Ausschnitt der Sitemap gespeichert in filename
def extract_links(filename):
	with open(filename) as file:
		soup = BeautifulSoup(file, "html.parser")
		links = []
		for liste in soup.find_all('ul'): #geht durch alle listen durch
			for li_tag in liste.children: #geht durch alle listenelemente durch
					if li_tag.name == "li": #check ob mit li-element zu tun haben
						a_tag = li_tag.a 
						if a_tag != None: #check ob Link darin
							if a_tag.get('href') != None: #check ob link nicht leer
								links.append(a_tag.get('href')) #extrahiert die links
		return links
		#finde hier den Tag <u> und was ist lineare Algebra


#Geht durch eine Liste an Links durch und speichert die an storage_places. Speichert die Liste der Speicherorte der erfolgreich gescrapten URLs in index_name im Hauptordner
#Kann als Argumente die links aus extract_links erhalten
def scrape_db(links, storage_places, index_name):
	not_successful = []
	for i in range(0, len(links)): 
		try: #wenn Fehler, dann scraping dieser URL nicht erfolgreich
			urllib.request.urlretrieve(links[i], storage_places[i])
			print("Scraping file "+storage_places[i]+" successful")
		except:
			print("Scraping file "+storage_places[i]+" not successful")
			not_successful.append(i)
	with open(index_name, "w+") as file:
		for i in range(0, len(links)):
			if not i in not_successful:
				file.write(storage_places[i]+'\n')

#Liest die Liste erfolgreich gescrapter URLs ein aus filename
def get_scraped_wiki_pages(filename):
	list_of_pages = []
	with open(filename) as file:
		list_of_pages = [line.rstrip('\n') for line in file]
	return list_of_pages



"""Generiert die author_dicts"""
"""author_dicts sind ein Dictionary mit dem Autor*innennamen als Key und als Values eine Liste einzelner Bearbeitungsevents. Die Bearbeitungsevents haben das folgende Format: [Artikelname, date]
Beispiel: 'Boehm': [['test2', datetime.date(2015, 12, 8)]] mit test2 als hypothetischer Artikelname"""

#Generiert das vollen author_dict ausgehend von einer Liste an gescrapten Seiten (eingetragen in wiki_index.txt)
def get_full_author_dict_from_wiki(index_file):
	list_of_pages = get_scraped_wiki_pages(index_file)
	list_of_names = list(map(get_name, list_of_pages)) #schöne Namen ausgehend von den Links
	author_dict = dict()
	for i in range(0, len(list_of_pages)):#Geht durch jeden Artikel durch und ergänzt das author_dict
		author_dict = get_author_dict(list_of_names[i], list_of_pages[i], author_dict)
	return author_dict

#Generiert das author_dict in einer gewissen Zeitspanne
def get_author_dict_timespan(author_dict, tage):
	tage = timedelta(days = tage)
	limit_date = date.today()-tage
	for key in author_dict:
		values_in_timespan = []
		for event in author_dict[key]: 
			if event[1] > limit_date:
				values_in_timespan.append(event)
			else: #schon Absteigend nach Datum sortiert, deswegen kann man da Iteration abbrechen
				break
		author_dict[key] = values_in_timespan
	return author_dict

#Generiert ein author_dict neu anhand eines gescrapten Artikels, oder updated ein bestehendes
def get_author_dict(article_name, article_file, author_dict=dict()):
	with open(article_file) as file:
		soup = BeautifulSoup(file, "html.parser")
		liste = soup.find_all(id='pagehistory')[0]
		for li_tag in liste.children: 
			if li_tag.name == "li": #Geht alle Elemente in der Visionsgeschichte durch (einzige Liste auf der Seite)
				date_str = str(list(li_tag.find('a', { "class" : "mw-changeslist-date"}).children)[0]) #Holt den Datumsstring raus
				author_name = str(li_tag.bdi.string) #Holt den Autor*innennamen raus
				if author_name in author_dict: #Wenn Autor*in schon in dictionary, dann Update, sonst neu hinzugefügt
					author_dict[author_name].append([article_name, convert_to_date(date_str)])
				else:
					author_dict[author_name] = [[article_name, convert_to_date(date_str)]]
		for key in author_dict: #Absteigende Sortierung nach Datum
			author_dict[key].sort(key=get_second, reverse=True)
		return author_dict			

def actualize_sitemap():
	urllib.request.urlretrieve('https://de.wikibooks.org/w/index.php?title=Mathe_f%C3%BCr_Nicht-Freaks:_Sitemap', "sitemap.html")
	with open("sitemap.html") as file:
		soup = BeautifulSoup(file, "html.parser")
		#print(soup.body)
		titles = soup.find_all('h2')
		for i in range(1, 6):#Ignoriere das Inhaltsverzeichnis und die Buchanfänge
			sitemap_links = ["sitemap_files/grund_sitemap.html", "sitemap_files/ana_sitemap.html", "sitemap_files/lina_sitemap.html", "sitemap_files/mass_sitemap.html", "sitemap_files/real_sitemap.html"]
			with open(sitemap_links[i-1], "w+") as file2:
				file2.write(str(titles[i]))
				while titles[i].next_sibling != titles[i+1]: #Writing every content between two h2-titles (subjects) inside document
					titles[i] = titles[i].next_sibling
					file2.write(str(titles[i]))



def calculate_authors_topic(fach, days_to_go_back):
	author_dict = dict()
	author_dict = get_full_author_dict_from_wiki(fach[2]) #berechnet den author_dict für das Fach mit der Nummer
	author_dict_timespan = get_author_dict_timespan(author_dict, days_to_go_back) #falsche Bennenung. Berechnet den author_dict für die letzten xy Tage
	return sorted([[author[0], len(author[1])] for author in author_dict_timespan.items() if len(author[1])>=10], key=lambda author: author[1], reverse=True)

def calculate_all_authors(faecher, day_to_go_back):
	author_dict = dict()
	for fach in faecher:
		print("Calculating "+fach[0])
		list_of_pages = get_scraped_wiki_pages(fach[2])
		list_of_names = list(map(get_name, list_of_pages)) #schöne Namen ausgehend von den Links
		for i in range(0, len(list_of_pages)):#Geht durch jeden Artikel durch und ergänzt das author_dict
			author_dict = get_author_dict(list_of_names[i], list_of_pages[i], author_dict)
	author_dict_timespan = get_author_dict_timespan(author_dict, eingabe2) #falsche Bennenung. Berechnet den author_dict für die letzten xy Tage
	return sorted([[author[0], len(author[1])] for author in author_dict_timespan.items() if len(author[1])>=10], key=lambda author: author[1], reverse=True)




"""Ausgabebefehle"""
#Liste aller Fächer mit sitemap-files und wiki-files (Listen der gescrapten Artikel)
faecher = [["Analysis 1", "sitemap_files/ana_sitemap.html", "index_files/ana_index.txt"], ["Lineare Algebra", "sitemap_files/lina_sitemap.html", "index_files/lina_index.txt"], ["Real Analysis", "sitemap_files/real_sitemap.html", "index_files/real_index.txt"], ["Grundlagen der Mathematik", "sitemap_files/grund_sitemap.html", "index_files/grund_index.txt"], ["Maßtheorie", "sitemap_files/mass_sitemap.html", "index_files/mass_index.txt"]] #, ["Buchanfänge", "sitemap_files/buch_sitemap.html", "index_files/buch_index.txt"], ["Mitmachen für (Nicht-)Freaks", "sitemap_files/mitm_sitemap.html", "index_files/mitm_index.txt"]

eingabe = str(input("Speedymode? y für Ja und n für Nein"))
if "y" in eingabe:
	print("Scrape Sitemap:\n")
	actualize_sitemap()
	print("Scrape Datenbank:\n")
	for fach in faecher: #scrapt für jedes Fach neu die history-Seiten
		print("\n\nScrape Fach: "+fach[0]+"\n")
		articles = extract_links(fach[1]) #liest verlinkte Artikel ein
		links = list(map(get_history_link, articles)) #generiert "echte" Links
		storage_places = list(map(get_storage_place, articles)) #kreiert eine Liste der storage_places
		scrape_db(links, storage_places, fach[2]) #Scrapt die Webseite
	eingabe2 = 90
	authors = calculate_all_authors(faecher, eingabe2)
	print("\nAnzahl Autor*innen: %s"%len(authors))
	print("Autor*innen:")
	for author in authors:
		print(author[0]+": "+str(author[1]))
	print("\n")

	for fach in faecher:
		print(fach[0])
		authors = calculate_authors_topic(fach, eingabe2)
		print("Autor*innen %s"%fach[0])
		print("\nAnzahl Autor*innen: %s"%len(authors))
		print("Autor*innen:")
		for author in authors:
			print(author[0]+": "+str(author[1]))
		print("\n \n")
else:
	eingabe = str(input("Wollen Sie die Datenbank/Bearbeitungshistorien neu scrapen? Drücken Sie y für Ja und n für Nein\n"))
	if "y" in eingabe:
		eingabe = str(input("Wollen sie die Sitemap neu scrapen? Drücken Sie y für Ja und n für Nein\n"))
		if "y" in eingabe:
			print("Scrape Sitemap:\n")
			actualize_sitemap()
		print("Scrape Datenbank:\n")
		for fach in faecher: #scrapt für jedes Fach neu die history-Seiten
			print("\n\nScrape Fach: "+fach[0]+"\n")
			articles = extract_links(fach[1]) #liest verlinkte Artikel ein
			links = list(map(get_history_link, articles)) #generiert "echte" Links
			storage_places = list(map(get_storage_place, articles)) #kreiert eine Liste der storage_places
			scrape_db(links, storage_places, fach[2]) #Scrapt die Webseite


	eingabe2 = int(input("Wieviel Tage sollen wir zurück gehen?"))

	eingabe = input("Wollen Sie die Gesamtstatistik? Drücken Sie y für Ja und n für Nein:")

	if "y" in eingabe:
		authors = calculate_all_authors(faecher, eingabe2)
		print("\nAnzahl Autor*innen: %s"%len(authors))
		print("Autor*innen:")
		for author in authors:
			print(author[0]+": "+str(author[1]))
		print("\n")

	eingabe = int(input("Wofür wollen sie die Autor*innenstatistik pro Fach? Geben sie hier die Nummer ein: \n0 : Analysis 1\n1 : Lineare Algebra 1\n2: real Analysis\n3: Grundlagen der Mathematik\n4 : Maßtheorie\n5: Alle Fächer"))


	if eingabe == 5:
		for fach in faecher:
			print(fach[0])
			authors = calculate_authors_topic(fach, eingabe2)
			print("Autor*innen %s"%fach[0])
			print("\nAnzahl Autor*innen: %s"%len(authors))
			print("Autor*innen:")
			for author in authors:
				print(author[0]+": "+str(author[1]))
			print("\n \n")
		
	else:
		fach = faecher[eingabe]
		authors = calculate_authors_topic(fach, eingabe2)
		print("Autor*innen %s"%faecher[eingabe][0])
		print("\nAnzahl Autor*innen: %s"%len(authors))
		print("Autor*innen:")
		for author in authors:
			print(author[0]+": "+str(author[1]))






