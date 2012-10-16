import copy
import re
import sys
import urllib2

from BeautifulSoup import BeautifulSoup 
from calidadaguas import Sample
from calidadaguas import SamplePoint

class NayadeScraping:
  beaches = []

  def scrap(self, id):
    data_soup = BeautifulSoup(urllib2.urlopen('http://nayade.msc.es/Splayas/ciudadano/ciudadanoVerZonaAction.do?codZona=' + str(id)).read())
    # Get the beach samples.
    samples_soup = BeautifulSoup(urllib2.urlopen('http://nayade.msc.es/Splayas/ciudadano/ciudadanoVerZonaAction.do?pestanya=3&codZona=' + str(id)).read())

    # This is ugly as hell, but I'm not used to BeautifulSoup.
    data_values = data_soup.findAll('td', {'class' : 'valorCampoI'})

    # Check is this a valid ID. There are some keys that are not present, in that case, we continue.
    if data_values[5].string == None:
      return

    sample_points = samples_soup.findAll('td', {'class' : 'nombreCampoNI'})
    points = []
    samples = []
    for i in range(0, len(sample_points), 6):
      sample_point = SamplePoint.SamplePoint()
      sample_point.name = sample_points[i].string
      point = data_soup.find(text = re.compile(sample_point.name[-5:].strip()))
      # There are two empty tds. This is awesomic.
      geodata = point.findNext('td', {'class' : 'valorCampoI'})
      geodata = geodata.findNext('td', {'class' : 'valorCampoI'})
      geodata = geodata.findNext('td', {'class' : 'valorCampoI'})
      sample_point.x = geodata.string
      geodata = geodata.findNext('td', {'class' : 'valorCampoI'})
      sample_point.y = geodata.string
      points.append(sample_point)

      # Parse the current samples.
      tds = sample_points[i].findAllNext('td', {'class' : 'valorCampoI'})
      for j in range(0, len(tds), 4):
        sample = Sample.Sample()
        sample.date = tds[j].string
        sample.escherichia_coli = tds[j+1].string
        sample.enterococo = tds[j+2].string
        sample.notes = tds[j+3].string
        sample.samplepoint = sample_point
        samples.append(sample)
        if tds[j+3].findNext('td').findNext('td').findNext('td').get('class', None) == 'nombreCampoNI':
          break

    # We cannot rely in the order in which tds are created, because some data is variable.
    # Parse again looking for the UTM coordinates.

    # Generate the beach structure as it will be written in csv columns.
    beach = { 
      'Comunidad': data_values[0].string,
      'Provincia': data_values[1].string,
      'Municipio': data_values[2].string,
      'Nombre': data_values[5].string,
      'adoptada_por': 'penyaskito (scrapping)',
    }
    # Normalize data. We need to strip bad chars that could act as separators and fix the encoding.
    for key, value in beach.iteritems():
      beach[key] = value.strip().encode("utf-8")     

    # Save a row for each sample point.
    for sample in samples:
      print 'Data obtained for' , beach['Nombre'], 'with id', id, 'and sample', sample.samplepoint.name, sample.date
      beach['punto_muestreo'] = sample.samplepoint.name
      beach['utm_x'] = sample.samplepoint.x
      beach['utm_y'] = sample.samplepoint.y
      beach['fecha_toma'] = sample.date
      beach['escherichia_coli'] = sample.escherichia_coli
      beach['enterococo'] = sample.enterococo
      beach['observaciones'] = sample.notes

      # Save the sample point
      self.beaches.append(copy.copy(beach))
