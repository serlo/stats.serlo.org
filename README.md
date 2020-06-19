# MfNF-Collaborator-Numbers
Generates an overview of all collaborators and their edits for the Wikibooks-project ["Mathe für Nicht-Freaks"](https://de.wikibooks.org/wiki/Mathe_f%C3%BCr_Nicht-Freaks). This is based on the [Sitemap](https://de.wikibooks.org/w/index.php?title=Mathe_f%C3%BCr_Nicht-Freaks:_Sitemap)

```
conda env create --file authorsMfNF.yml
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

Then use `python report_email.py` to send the report to the receivers-email or use `python authorsMfNF.py` to generate the docx-report (check report.docx file): both call `report()-function`.
