# encoding: utf-8

# nayade-stats.rb

# Utilidad que muestra estadísticas por comunidades autónomas de la cantidad
# de playas que están actualizadas en el último año y años anteriores.

# Autor: @manufloresv (Manuel Flores)
# Licencia: MIT License

# Uso: ruby src/nayade-stats.rb

require 'csv'
require 'date'

carga = CSV.read("data/calidad-aguas.csv")
carga.shift

hcomunidades = carga.group_by {|row| row[0] }

hcomunidades.each do |comunidad, rows|
	puts comunidad
	
	hyears = rows.group_by do |row|
		Date.parse(row[9]).year
	end

	hyears.each do |year, rows2|
		puts "- Última toma realizada en #{year}: #{rows2.size} playas"
	end
	puts

end