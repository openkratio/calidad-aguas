import urllib2

from BeautifulSoup import BeautifulSoup 

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

    # We cannot rely in the order in which tds are created, because some data is variable.
    # Parse again looking for the UTM coordinates.
    x = data_soup.find(text="Coordenadas UTM");
    geo = x.parent.parent.findAll('td', {'class':'valorCampoI'})

    # Parse the samples table.
    sample_values = samples_soup.findAll('td', {'class' : 'valorCampoI'})

    # Generate the beach structure as it will be written in csv columns.
    beach = { 
      'Comunidad': data_values[0].string,
      'Provincia': data_values[1].string,
      'Municipio': data_values[2].string,
      'Nombre': data_values[5].string,
      'punto_muestreo': data_values[18].string,
      'adoptada_por': 'penyaskito (scrapping)',
      'utm_x': geo[0].string,
      'utm_y': geo[1].string,
      'fecha_toma': sample_values[0].string,
      'escherichia_coli': sample_values[1].string,
      'enterococo': sample_values[2].string,
      'observaciones': sample_values[3].string,
    }
    # Normalize data. We need to strip bad chars that could act as separators and fix the encoding.
    for key, value in beach.iteritems():
      beach[key] = value.strip().encode("utf-8")
    # Some user feedback, we should be doing this on batches.
    print 'Data obtained for' , beach['Nombre'], ' with id ', id
    self.beaches.append(beach) 
