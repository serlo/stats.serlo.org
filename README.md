# MfNF-Collaborator-Numbers
Generates an overview of all collaborators and their edits for the Wikibooks-project ["Mathe für Nicht-Freaks"](https://de.wikibooks.org/wiki/Mathe_f%C3%BCr_Nicht-Freaks). This is based on the [Sitemap](https://de.wikibooks.org/w/index.php?title=Mathe_f%C3%BCr_Nicht-Freaks:_Sitemap)

```
conda env create --file authors_MfNF.yml
conda activate authorsMfNF
```

Stores the data inside a SQL-Database and allows further analysis from there. Create a `config.json` in your main-folder with:

```json
{
	"db": {
		"host": "host",
		"user": "user",
		"password": "pw",
                "database": "EDITS"
    },
    "topics": ["Grundlagen der Mathematik", "Analysis 1", "Lineare Algebra 1","Maßtheorie","Real Analysis", "Mitmachen für (Nicht-)Freaks"]
}
 
```

Then use `python docx_report.py` to generate/actualize the docx-report (check report.docx file) or `python email_report.py` to generate/actualize the report and send it to the receivers-email: both call `report()-function`. Still the main magic happens in authors_MfNF.py and databbase.py.
