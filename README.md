# MfNF-Collaborator-Numbers
Generates an overview of all collaborators and their edits for the Wikibooks-project ["Mathe für Nicht-Freaks"](https://de.wikibooks.org/wiki/Mathe_f%C3%BCr_Nicht-Freaks). This is based on the [Sitemap](https://de.wikibooks.org/w/index.php?title=Mathe_f%C3%BCr_Nicht-Freaks:_Sitemap)

```
conda env create --file authors_MfNF.yml
conda activate authorsMfNF
```

Create a `credentials.json` in your main-folder with:

```json
{
        "email": {
                "user": "username",
                "pw": "password",
                "smtp_server": "your smtp-server",
                "smtp_port": "your smtp-server port",
                "receivers": "receiver-emails"
        }
}
```

Then use `python docx_report.py` to generate/actualize the docx-report (check report.docx file) or `python email_report.py` to generate/actualize the report and send it to the receivers-email: both call `report()-function`. Still the main magic happens in authors_MfNF.py and databbase.py.
