#!/bin/bash
#
# eea-xls2csv.sh versión 0.1 (21/05/2013)

# Conversor a csv de la información sobre calidad de aguas de baño publicado por la 
# European Environmental Agency (EEA) para la iniciativa #adoptaunaplaya - http://adoptaunaplaya.es/site/

# Autor: @fontanon "J. Félix Ontañón" <felixonta@gmail.com>
# Licencia: GPLv3 License

# Uso: ./eea-xls2csv.sh

# Explicación:
# Este script descarga el fichero zip con las hojas de cálculo Excel
# y realiza una conversión a un único fichero CSV.

# Dependencias:
# xls2csv: Conversor xls a csv. Proyecto CatDoc http://freecode.com/projects/catdoc
# wget: Herramienta de descarga. Proyecto GNU http://www.gnu.org/software/wget/
# unzip: Utilidad de decompresión ZIP. Proyecto ZIP http://www.info-zip.org/UnZip.html

# URL de descarga del fichero ZIP. Ultima consulta 21/05/2013
BWD_V6_URL="http://www.eea.europa.eu/data-and-maps/data/bathing-water-directive-status-of-bathing-water-5/bathing-water-directive-status-1990-2012/excel-format-zip/at_download/file"

# Nombre de fichero salida
OUT_FILE="eea-calidad-aguas.csv"

# Variables usadas para las transformaciones temporales
TMP_DIR="/tmp/bwd_tmp"
DLD_FILE="bwd.zip"
SHEET_SEPARATOR="sheet_separator"

# Descarga y conversión
mkdir -p $TMP_DIR
wget $BWD_V6_URL -O $TMP_DIR/$DLD_FILE
unzip -o $TMP_DIR/$DLD_FILE -d $TMP_DIR
echo '"cc","BWID","SeaRegion","Region","Province","Commune","BWName","BWaterCat","Longitude_BW","Latitude_BW","y1990","y1991","y1992","y1993","y1994","y1995","y1996","y1997","y1998","y1999","y2000","y2001","y2002","y2003","y2004","y2005","y2006","y2007","y2008","y2009","y2010","y2011","y2012","y2012 comment"' > $OUT_FILE
xls2csv -b$SHEET_SEPARATOR $TMP_DIR/*xls | sed -n /$SHEET_SEPARATOR/,/$SHEET_SEPARATOR/p | grep -v $SHEET_SEPARATOR >> $OUT_FILE
echo "Finished! Outfile: " $OUT_FILE
