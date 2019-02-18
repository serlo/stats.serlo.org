from fluent import sender
from fluent import event
import urllib.request
import urllib.parse
import json
import dateutil.parser

API_ENDPOINT = "https://de.wikibooks.org/w/api.php?action=query&prop=revisions&titles={}&rvlimit=max&rvprop=ids|timestamp|user|userid|comment|size&format=json"

def get_edits_of_page(title):
    title = urllib.parse.quote(title)
    content = json.load(urllib.request.urlopen(API_ENDPOINT.format(title)))
    return list(content["query"]["pages"].values())[0]["revisions"]

logger = sender.FluentSender("mfnf.edits", host="localhost", port=8889)

for edit in get_edits_of_page("Mathe_für_Nicht-Freaks:_Zahlengerade"):
    print (edit)
    time = dateutil.parser.parse(edit["timestamp"])
    logger.emit_with_time("revision", time.timestamp(), edit)
