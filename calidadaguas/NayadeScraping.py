import copy
import re
import sys
import urllib2

from BeautifulSoup import BeautifulSoup 
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

    sample_points = samples_soup.findAll('td', {'class' : 'nombreCampoNI'});
    points = []
    for i in range(0, len(sample_points), 6):
      sample_point = SamplePoint.SamplePoint()
      sample_point.name = sample_points[i].string
      geodata = data_soup.find(text = re.compile(sample_point.name.replace('PLAYA  ', '').strip()))

      # There are two empty tds. This is awesomic.
      geodata = geodata.findNext('td', {'class' : 'valorCampoI'})
      geodata = geodata.findNext('td', {'class' : 'valorCampoI'})
      geodata = geodata.findNext('td', {'class' : 'valorCampoI'})
      sample.x = geodata.string
      geodata = geodata.findNext('td', {'class' : 'valorCampoI'})
      sample.y = geodata.string
      points.append(sample_point)
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
    for point in points:
      print 'Data obtained for' , beach['Nombre'], 'with id', id, 'and sample', point.name
      beach['punto_muestreo'] = point.name
      beach['utm_x'] = point.x
      beach['utm_y'] = point.y



      # Save the sample point
      self.beaches.append(copy.copy(beach))
