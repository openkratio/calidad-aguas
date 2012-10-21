# encoding: utf-8

# nayade.rb versión 0.2 (21/10/2012)

# Scraping al Sistema de Información Nacional de Aguas de Baño (Náyade)
# para la iniciativa #adoptaunaplaya - http://adoptaunaplaya.es/site/

# Autor: @manufloresv (Manuel Flores)
# Licencia: MIT License

# Uso:
# ruby nayade.rb [--todas|--ultimas] [<comienzo>] [<final>] > csv.csv
# --todas     todas las mediciones
# --ultimas   solo la medición más reciente (opcional, por defecto)
# <comienzo>  código de la primera playa (1 por defecto)
# <final>     código de la última playa (constante final por defecto)

# Ejemplo completo:
# ruby nayade.rb > calidad-aguas.csv
# ruby nayade.rb --todas > calidad-aguas-historico.csv

# Ejemplo por tramos:
# ruby nayade.rb 1 500 > calidad-aguas.csv
# ruby nayade.rb 501 1000 >> calidad-aguas.csv
# ruby nayade.rb 1001 >> calidad-aguas.csv

# Explicación:
# En Náyade cada zona de baño está numerada con un código entre 1 y 1976.
# Este script pide las páginas con los datos de localización y muestreos de
# cada zona de baño, extrae los valores y devuelve un fichero CSV.
# He usado expresiones regulares en vez de XPath debido a que en el HTML de
# la web de Náyade se usa el mismo atributo class para los diferentes datos.

require 'net/http'
require 'uri'
require 'cgi'
require 'csv'

NAYADE_URL = "http://nayade.msc.es/Splayas/ciudadano/ciudadanoVerZonaAction.do"
MAX_PLAYAS = 1976

class String
  def td_scan(label, prefix="")
    # expresión regular para obtener el valor de la siguiente celda a la que tiene una cadena de texto dada
    self.scan(/#{label}:<.+\s+.+>#{prefix}(.+)</)
  end
end

def playa(cod, historico)
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

    submuestreos = muestreos.split("Punto Muestreo:")
    submuestreos.shift

    submuestreos.each_index do |i|
      arrayout = [comunidad, provincia, municipio, nombre,
        pm[i][0], "nayade.rb", x[i][0], y[i][0], huso[i][0]]

      # expresión regular para obtener todas las mediciones
      toma = Regexp.new('<' + '.+\s+.+valorCampoI">(.+)<' * 4)
      mediciones = submuestreos[i].scan(toma)

      if mediciones.empty?
        $stderr.puts ": Playa sin muestreos."
        return
      end

      $stderr.print "\b"*4 # borrar cod actual de stderr

      puts (arrayout + mediciones[0]).to_csv # última medición

      if historico then
        mediciones[1..-1].each do |m| # resto de mediciones
          puts (arrayout + m).to_csv
        end
      end
    end

  rescue StandardError
    $stderr.puts ": Aquí no hay playa, vaya vaya." # hay códigos sin asignar a zonas de baño
  rescue Interrupt
    exit
  end
end

todas = ARGV.delete("--todas") != nil
ultimas = ARGV.delete("--ultimas") != nil
first = ARGV[0] ? ARGV[0].to_i : 1
last = ARGV[1] ? ARGV[1].to_i : MAX_PLAYAS

cabecera = %w(Comunidad Provincia Municipio Nombre punto_muestreo adoptada_por
  utm_x utm_y utm_huso fecha_toma escherichia_coli enterococo observaciones)
puts cabecera.to_csv if first==1

(first..last).each { |cod| playa(cod, todas) }
