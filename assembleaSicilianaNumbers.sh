#!/bin/bash

#set -x

### requisiti ###
# csvkit https://csvkit.readthedocs.io
# jq https://stedolan.github.io/jq/
# pup https://github.com/ericchiang/pup
### requisiti ###

# faccio pulizia nella cartella corrente
rm ./PF*.json 
rm ./CF*.json 

# recupero gli indirizzi dei gruppi
indirizziGruppi=($(curl -s "http://www.ars.sicilia.it/deputati/gruppi.jsp" | pup '#myTable > tbody > tr > td:nth-child(2) > a attr{href}' | tr "\n" " "))

# ciclo per ogni gruppo
for m in "${indirizziGruppi[@]}"
do
  uri="http://www.ars.sicilia.it/deputati/""${m}"
# recupero URL dei deputati  
  indirizziDeputatii=($(curl -s "$uri" | pup '#myTable > tbody > tr > td:nth-child(2) > a[href*="scheda.jsp"] attr{href}'))
  idGruppo=$(echo "$m" | sed -r 's/^.*dGruppo=//g')
# per ogni pagina di un deputato estraggo il numero di attività svolte da primo firmatario e da cofirmatario
  for n in "${indirizziDeputatii[@]}"
  do
    uriDeputato=$(echo "http://www.ars.sicilia.it/deputati/""${n}" | sed 's/&amp;/\&/g')
    idDeputato=$(echo "$uriDeputato" | sed -r 's/^.*utato=//g')
    echo "$uriDeputato"",""$idGruppo"
    curl -s "$uriDeputato" | scrape -be "//table[2]//tr[5]/td[3]/table//tr[2]/td" | xml2json | jq '[.html.body.td | {idGruppo:'"$idGruppo"',idDeputato:'"$idDeputato"',DisegnidiLegge:."$t"[0]|gsub("(\\[|\\])";""),InterrogazioniParlamentari:."$t"[1]|gsub("(\\[|\\])";""),InterpellanzeParlamentari:."$t"[2]|gsub("(\\[|\\])";""),Mozioni:."$t"[3]|gsub("(\\[|\\])";""),Ordinidelgiorno:."$t"[4]|gsub("(\\[|\\])";"")}]' > PF_"$idDeputato".json
    curl -s "$uriDeputato" | scrape -be "//table[2]//tr[5]/td[3]/table//tr[5]/td" | xml2json | jq '[.html.body.td | {idGruppo:'"$idGruppo"',idDeputato:'"$idDeputato"',DisegnidiLegge_co:."$t"[0]|gsub("(\\[|\\])";""),InterrogazioniParlamentari_co:."$t"[1]|gsub("(\\[|\\])";""),InterpellanzeParlamentari_co:."$t"[2]|gsub("(\\[|\\])";""),Mozioni_co:."$t"[3]|gsub("(\\[|\\])";""),Ordinidelgiorno_co:."$t"[4]|gsub("(\\[|\\])";""),uriDeputato:"'"$uriDeputato"'"}]' > CF_"$idDeputato".json
  done
done

# unisco i vari JSON di output creati
jq -s '.' PF*.json > primofirmatario.json
jq -s '.' CF*.json > cofirmatario.json

# converto in CSV gli output di sopra
in2csv primofirmatario.json > primofirmatario.csv
in2csv cofirmatario.json > cofirmatario.csv

sed -i 's/0\///g' primofirmatario.csv
sed -i 's/0\///g' cofirmatario.csv

# faccio il join tra la tabella dei dati sui primi firmatari e quella dei cofirmatari
csvjoin -c 2 primofirmatario.csv cofirmatario.csv > attivitaDeputatiRegioneSiciliana_tmp.csv
csvsql --query "select * from attivitaDeputatiRegioneSiciliana_tmp order by idGruppo,idDeputato" attivitaDeputatiRegioneSiciliana_tmp.csv > attivitaDeputatiRegioneSiciliana.csv

# faccio pulizia nella cartella corrente
rm ./attivitaDeputatiRegioneSiciliana_tmp.csv
rm ./PF*.json 
rm ./CF*.json 

# sposto tutto in data
mkdir -p ./data
mv *.json ./data/
mv *.csv ./data/
