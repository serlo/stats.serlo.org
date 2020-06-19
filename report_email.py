import smtplib
import json
import os.path
from email.mime.multipart import MIMEMultipart 
from email.mime.text import MIMEText 
from email.mime.base import MIMEBase 
from email import encoders 
from datetime import date

import authorsMfNF as am


def main():
   config = json.load(open("credentials.json", "r"))

   user = config["email"]["user"]
   pw = config["email"]["pw"]

   smtp_server = config["email"]["smtp_server"]
   smtp_port = config["email"]["smtp_port"]

   receivers = config["email"]["receivers"]


   topics = ["Grundlagen der Mathematik", "Analysis 1", "Lineare Algebra 1","Maßtheorie","Real Analysis", "Mitmachen für (Nicht-)Freaks"] #, ["Buchanfänge", "sitemap_files/buch_sitemap.html", "index_files/buch_index.txt"], ["Mitmachen für (Nicht-)Freaks", "sitemap_files/mitm_sitemap.html", "index_files/mitm_index.txt"]
   if not os.path.isdir("topic_frames"):
      am.report(topics, initialize=True, actualize=False)
   else:
      am.report(topics)


   msg = MIMEMultipart() 
   msg['From'] = user 
   msg['To'] = receivers 
   msg['Subject'] = "Report MfNF"
   body = "Anbei findest du den Report zur Autor*innenstatistik von MfNF vom %s. Lg "%date.today()
   msg.attach(MIMEText(body, 'plain')) 
   
   # open the file to be sent  
   filename = "report.docx"
   attachment = open("report.docx", "rb") 
   p = MIMEBase('application', 'octet-stream') 
   p.set_payload((attachment).read()) 
   encoders.encode_base64(p)
   p.add_header('Content-Disposition', "attachment; filename= %s" % filename) 
   msg.attach(p) 

   try: 
      smtpObj = smtplib.SMTP(smtp_server, smtp_port)
      smtpObj.starttls()
      smtpObj.login(user, pw)

      text = msg.as_string() 

      smtpObj.sendmail(user, receivers, text)    
      smtpObj.quit()     
      print("Successfully sent email")
   except:
      print("Error: unable to send email")


if __name__=="__main__":
   main()