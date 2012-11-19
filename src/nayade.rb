# encoding: utf-8

# nayade.rb versión 0.3 (17/11/2012)

# Scraping al Sistema de Información Nacional de Aguas de Baño (Náyade)
# para la iniciativa #adoptaunaplaya - http://adoptaunaplaya.es/site/

# Autor: @manufloresv (Manuel Flores)
# Licencia: MIT License

# Uso: ruby nayade.rb
# Fichero de configuración: config.yml

# Explicación:
# En Náyade cada zona de baño está numerada con un código entre 1 y 1976.
# Este script pide las páginas con los datos de localización y muestreos de
# cada zona de baño, extrae los valores y los guarda en ficheros CSV.
# He usado expresiones regulares en vez de XPath debido a que en el HTML de
# la web de Náyade se usa el mismo atributo class para los diferentes datos.

require 'net/http'
require 'uri'
require 'cgi'
require 'csv'
require 'yaml'

NAYADE_URL = "http://nayade.msc.es/Splayas/ciudadano/ciudadanoVerZonaAction.do"
MAX_PLAYAS = 1976

@count = 0

class NayadeError < StandardError
end

class String
  def td_scan(label, prefix="")
    # expresión regular para obtener el valor de la siguiente celda a la que tiene una cadena de texto dada
    self.scan(/#{label}:<.+\s+.+>#{prefix}(.+)</)
  end
end

def playa(cod)
  ultimas = ""
  todas = ""
  log = ""

  begin
    localizacion = Net::HTTP.get URI.parse(NAYADE_URL + "?codZona=#{cod}")
    localizacion.encode!("UTF-8","ISO-8859-1")

    cpmn = ["Comunidad Autónoma", "Provincia", "Municipio", "Zona Agua Baño"]
    comunidad, provincia, municipio, nombre = cpmn.map do |i|
      v = localizacion.td_scan(i)
      raise NayadeError, "Aquí no hay playa, vaya vaya." if v.empty?
      v.first.first
    end

    municipio = CGI.unescapeHTML(municipio.strip) # para el apóstrofo catalán

    nombre = nombre.strip.gsub("  ", " ")
    nombre = CGI.unescapeHTML(nombre)

    pm = localizacion.td_scan("Denominación", ".+PM") # sólo el número del punto de muestreo

    x, y, huso = ["X", "Y", "Huso"].map do |i|
      localizacion.td_scan(i)
    end

    muestreos = Net::HTTP.get URI.parse(NAYADE_URL + "?codZona=#{cod}&pestanya=3")
    muestreos.encode!("UTF-8", "ISO-8859-1")

    submuestreos = muestreos.split("Punto Muestreo:")
    submuestreos.shift

    submuestreos.each_index do |i|
      raise NayadeError, "Faltan coordenadas." if x[i].nil?
      
      arrayout = [comunidad, provincia, municipio, nombre,
        pm[i][0], "nayade.rb", x[i][0], y[i][0], huso[i][0]]

      # expresión regular para obtener todas las mediciones
      toma = Regexp.new('valorCampoI">(.+)<.+\s+.+' * 4)
      mediciones = submuestreos[i].scan(toma)

      raise NayadeError, "Playa sin muestreos." if mediciones.empty?

      ultimas << (arrayout + mediciones[0]).to_csv # última medición

      mediciones.each do |m| # todas las mediciones
        todas << (arrayout + m).to_csv
      end
    end

  rescue NayadeError => e
    log = "#{cod}: #{e.message}\n"
  end

  return [ultimas, todas, log]
end

def procesar_playas(inicio, fin)
  cad_ult = ""
  cad_hist = ""
  cad_log = ""

  (inicio..fin).each do |cod|
    res = playa(cod)
    cad_ult << res[0]
    cad_hist << res[1]
    cad_log << res[2]

    Thread.exclusive { @count+=1 }
  end

  return [cad_ult, cad_hist, cad_log]
end

# Leer configuración
Dir.chdir(File.dirname(__FILE__))
config = YAML.load_file("config.yml")
file_ult = config["ultimas"]
file_hist = config["historico"]
file_log = config["log"]
nthreads = config["nthreads"]

# Argumentos de entrada (utilizados para testeo)
first = ARGV[0] ? ARGV[0].to_i : 1
last = ARGV[1] ? ARGV[1].to_i : MAX_PLAYAS

# Cabecera del CSV
cabecera = %w(Comunidad Provincia Municipio Nombre punto_muestreo adoptada_por
  utm_x utm_y utm_huso fecha_toma escherichia_coli enterococo observaciones).to_csv

# Procesar las playas en paralelo
total = last-first+1
slice = total/nthreads # cantidad a procesar en cada thread
threads = []
array_ult = Array.new(nthreads) # datos de ultimas mediciones
array_hist = Array.new(nthreads) # historico de todas las mediciones
array_log = Array.new(nthreads) # log

nthreads.times do |t| # Lanzar n threads
  x = first + slice*t # inicio del bloque
  y = (t+1==nthreads) ? last : first + slice*(t+1) - 1 # fin del floque

  threads << Thread.new do
    array_ult[t], array_hist[t], array_log[t] = procesar_playas(x, y)
  end
end

# Monitorizar porcentaje
threads << Thread.new do
  loop do
    porcentaje = @count*100/total
    msg = "Procesadas #{@count} de #{total} playas... #{porcentaje}%"
    print msg + "\b"*msg.size
    break if @count==total
    sleep 1
  end
  puts
end

# Esperar que todos los threads acaben
threads.each(&:join)

# Escribir resultado en los ficheros
File.write(file_ult, cabecera + array_ult.join)
File.write(file_hist, cabecera + array_hist.join)
File.write(file_log, array_log.join)
