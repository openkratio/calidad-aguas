# encoding: utf-8

# nayade.rb versión 0.1 (18/10/2012)

# Scraping al Sistema de Información Nacional de Aguas de Baño (Náyade)
# para la iniciativa #adoptaunaplaya - http://adoptaunaplaya.es/site/

# Autor: @manufloresv (Manuel Flores)
# Licencia: MIT License

# Uso:
# ruby nayade.rb [primera] [ultima] > csv.csv

# Ejemplo completo:
# ruby nayade.rb > calidad-aguas.csv

# Ejemplo por tramos:
# ruby nayade.rb 1 500 > calidad-aguas.csv
# ruby nayade.rb 501 1000 >> calidad-aguas.csv
# ruby nayade.rb 1001 >> calidad-aguas.csv

# Explicación:
# En Náyade cada zona de baño está numerada con un código entre 1 y 1976.
# Este script pide las páginas con la datos de localización y muestreos de
# cada zona de baño, extrae los valores y devuelve un fichero CSV.
# He usado expresiones regulares en vez de XPath debido a que en el HTML de
# la web de Náyade se usa el mismo atributo class para los diferentes datos.

require 'net/http'
require 'uri'
require 'cgi'

NAYADE_URL = "http://nayade.msc.es/Splayas/ciudadano/ciudadanoVerZonaAction.do"
MAX_PLAYAS = 1976

class String
  def td_scan(label, prefix="")
    # expresión regular para obtener el valor de la siguiente celda a la que tiene una cadena de texto dada
    self.scan(/#{label}:<.+\s+.+>#{prefix}(.+)</)
  end
end

def playa(cod)
  begin
    $stderr.print cod # imprimir cod actual en stderr

    localizacion = Net::HTTP.get URI.parse(NAYADE_URL + "?codZona=#{cod}")
    localizacion.encode!("UTF-8","ISO-8859-1")

    cpmn = ["Comunidad Autónoma", "Provincia", "Municipio", "Zona Agua Baño"]
    comunidad, provincia, municipio, nombre = cpmn.map do |i|
      localizacion.td_scan(i).first.first
    end

    municipio = CGI.unescapeHTML(municipio) # para el apóstrofo catalán

    nombre = nombre.strip.gsub("  ", " ")
    nombre = CGI.unescapeHTML(nombre)

    pm = localizacion.td_scan("Denominación", ".+PM") # sólo el número del punto de muestreo

    x, y, huso = ["X", "Y", "Huso"].map do |i|
      localizacion.td_scan(i)
    end

    muestreos = Net::HTTP.get URI.parse(NAYADE_URL + "?codZona=#{cod}&pestanya=3")
    muestreos.encode!("UTF-8", "ISO-8859-1")

    # expresión regular para obtener la fila con el muestreo más reciente
    lolwtf = Regexp.new('Enterococo' + '.+\s+' * 5 + '.+\s+.+valorCampoI">(.+)<' * 4)
    ultimatoma = muestreos.scan(lolwtf)
    
    if ultimatoma.empty?
      $stderr.puts ": Playa sin muestreos."
      return
    end

    $stderr.print "\b"*4 # borrar cod actual de stderr

    pm.each_index do |i|
      arrayout = [comunidad, provincia, municipio, nombre] + [pm, x, y, huso].map {|x| x[i][0]} + ultimatoma[i]
      puts ("%s,"*5 + "nayade.rb" + ",%s"*7) % arrayout
    end

  rescue StandardError
    $stderr.puts ": Aquí no hay playa, vaya vaya." # hay códigos sin asignar a zonas de baño
  rescue Interrupt
    exit
  end
end

first = ARGV[0] ? ARGV[0].to_i : 1
last = ARGV[1] ? ARGV[1].to_i : MAX_PLAYAS
puts "Comunidad,Provincia,Municipio,Nombre,punto_muestreo,adoptada_por,utm_x,utm_y,utm_huso,fecha_toma,escherichia_coli,enterococo,observaciones" if first==1

(first..last).each { |cod| playa(cod) }
