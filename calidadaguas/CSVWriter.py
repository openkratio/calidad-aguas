import csv

class CSVWriter:
  def dump_data(self, beaches):
    # Got the data, let's write it using the template.
    with open('templates/calidad-aguas.template.csv', 'r') as template:
      template_reader = csv.DictReader(template)
      with open('data/calidad-aguas.csv', 'wb') as csvfile:
        writer = csv.DictWriter(csvfile, delimiter=';', quotechar='|', fieldnames = template_reader.fieldnames)
        writer.writeheader()
        for beach in beaches:
          writer.writerow(beach)
        csvfile.close()
      template.close() 
