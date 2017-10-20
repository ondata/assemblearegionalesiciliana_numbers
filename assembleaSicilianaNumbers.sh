#!/bin/bash

#set -x

### requisiti ###
# csvkit 1.0.2 https://csvkit.readthedocs.io
# jq https://stedolan.github.io/jq/
# pup https://github.com/ericchiang/pup
# scrape https://github.com/jeroenjanssens/data-science-at-the-command-line/blob/master/tools/scrape
# xml2json https://github.com/Inist-CNRS/node-xml2json-command
### requisiti ###

# svuoto la cartella data
rm -R ./data/*

# recupero gli indirizzi dei gruppi
indirizziGruppi=($(curl -s "http://www.ars.sicilia.it/deputati/gruppi.jsp" | pup '#myTable > tbody > tr > td:nth-child(2) > a attr{href}' | tr "\n" " "))

# ciclo per ogni gruppo
for m in "${indirizziGruppi[@]}"
do
  uri="http://www.ars.sicilia.it/deputati/""${m}"
# recupero URL dei deputati  
  indirizziDeputatii=($(curl -s "$uri" | pup '#myTable > tbody > tr > td:nth-child(2) > a[href*="scheda.jsp"] attr{href}'))
  idGruppo=$(echo "$m" | sed -r 's/^.*dGruppo=//g')
# estraggo i nomi dei gruppi
  curl -s "$uri" | scrape -be '//td[@id="pageContent"]' | xml2json | jq -r '.html.body.td.div | ['"$idGruppo"',."$t"] | @csv' >> ./tmp_anagraficaGruppi00.csv
# estraggo l'anagrafica dei deputati
  curl -s "$uri" | scrape -be '//td[@id="pageContent"]' | xml2json | jq -r '.html.body.td.table[1].tr[] | ['"$idGruppo"',.td[1].a."$t",.td[3]."$t",(.td[1].a.href | tostring | gsub("^.*Deputato="; ""))] | @csv' >> ./tmp_anagraficaDeputati.csv
# per ogni pagina di un deputato estraggo il numero di attività svolte da primo firmatario e da cofirmatario
  for n in "${indirizziDeputatii[@]}"
  do
    uriDeputato=$(echo "http://www.ars.sicilia.it/deputati/""${n}" | sed 's/&amp;/\&/g')
    idDeputato=$(echo "$uriDeputato" | sed -r 's/^.*utato=//g')
    echo "$uriDeputato"",""$idGruppo"
    curl -s "$uriDeputato" | scrape -be "//table[2]//tr[5]/td[3]/table//tr[2]/td" | xml2json | jq '[.html.body.td | {idDeputato:'"$idDeputato"',idGruppo:'"$idGruppo"',DisegnidiLegge:."$t"[0]|gsub("(\\[|\\])";""),InterrogazioniParlamentari:."$t"[1]|gsub("(\\[|\\])";""),InterpellanzeParlamentari:."$t"[2]|gsub("(\\[|\\])";""),Mozioni:."$t"[3]|gsub("(\\[|\\])";""),Ordinidelgiorno:."$t"[4]|gsub("(\\[|\\])";"")}]' > PF_"$idDeputato".json
    curl -s "$uriDeputato" | scrape -be "//table[2]//tr[5]/td[3]/table//tr[5]/td" | xml2json | jq '[.html.body.td | {idDeputato:'"$idDeputato"',DisegnidiLegge_co:."$t"[0]|gsub("(\\[|\\])";""),InterrogazioniParlamentari_co:."$t"[1]|gsub("(\\[|\\])";""),InterpellanzeParlamentari_co:."$t"[2]|gsub("(\\[|\\])";""),Mozioni_co:."$t"[3]|gsub("(\\[|\\])";""),Ordinidelgiorno_co:."$t"[4]|gsub("(\\[|\\])";""),uriDeputato:"'"$uriDeputato"'"}]' > CF_"$idDeputato".json
  done
done

# unisco i vari JSON di output creati
jq -s add PF*.json > primofirmatario.json
jq -s add CF*.json > cofirmatario.json

# converto in CSV gli output di sopra
in2csv primofirmatario.json > primofirmatario.csv
in2csv cofirmatario.json > cofirmatario.csv

# aggiungo intestazione a anagrafica deputati
sed -i '1s/^/idGruppo,nome,collegio,idDeputato\n/' ./tmp_anagraficaDeputati.csv
# rimuovo i record con dati null o riferiti ad altro
csvsql -I --query 'select idDeputato,idGruppo,nome,collegio from tmp_anagraficaDeputati where collegio not like "Collegio di elezione"' ./tmp_anagraficaDeputati.csv > ./tmp_anagraficaDeputati_01.csv
# sposto il campo idDeputato a inizio tabella
csvsql -I --query 'select idDeputato,nome,collegio from tmp_anagraficaDeputati_01' ./tmp_anagraficaDeputati_01.csv > ./tmp_anagraficaDeputati_02.csv

# aggiungo la riga di intestazione a anagraficaGruppi
sed -i '1s/^/idGruppo,nomeGruppo\n/' ./tmp_anagraficaGruppi00.csv

# rimuovo eventuali gruppi che in anagrafica non hanno il nomeGruppo valorizzato
csvsql -I --query "select * FROM tmp_anagraficaGruppi00 where nomeGruppo is not null order by idGruppo" ./tmp_anagraficaGruppi00.csv > ./anagraficaGruppi.csv
cat ./anagraficaGruppi.csv > ./tmp_anagraficaGruppi00.csv

# faccio il join tra la tabella dei dati sui primi firmatari e quella dei cofirmatari e la riordino 
csvjoin -I -c 1 primofirmatario.csv cofirmatario.csv > tmp_attivitaDeputatiRegioneSiciliana00.csv
csvsql -I --query "select * from tmp_attivitaDeputatiRegioneSiciliana00 order by idGruppo,idDeputato" tmp_attivitaDeputatiRegioneSiciliana00.csv > tmp_attivitaDeputatiRegioneSiciliana.csv

# aggiungo l'anagrafica dei deputati ai dati sui firmatari
csvjoin -I -c 1 ./tmp_attivitaDeputatiRegioneSiciliana.csv ./tmp_anagraficaDeputati_02.csv > tmp_attivitaDeputatiRegioneSiciliana_02.csv

# sposto nomeGruppo di anagraficaGruppi a inizio tabella
csvsql -I --query "select distinct nomeGruppo,idGruppo from tmp_anagraficaGruppi00" tmp_anagraficaGruppi00.csv > tmp_anagraficaGruppi.csv

# aggiungo l'anagrafica dei gruppi ai dati sui firmatari
csvjoin -I -c 2 ./tmp_attivitaDeputatiRegioneSiciliana_02.csv ./tmp_anagraficaGruppi.csv > tmp_attivitaDeputatiRegioneSiciliana_03.csv

# aggiungo URL foto deputato
csvsql -I --query "select *, 'http://www.ars.sicilia.it/DocumentiEsterni/Immagini/Deputati/'||substr('000000'||idDeputato, -6, 6)||'.jpg' as URLfoto from tmp_attivitaDeputatiRegioneSiciliana_03" ./tmp_attivitaDeputatiRegioneSiciliana_03.csv > ./tmp_attivitaDeputatiRegioneSiciliana_04.csv

# rimuovo i deputati doppioni raggruppando per idDeputato
csvsql -I --query "select * FROM tmp_attivitaDeputatiRegioneSiciliana_04 group by idDeputato order by idDeputato" ./tmp_attivitaDeputatiRegioneSiciliana_04.csv > ./attivitaDeputatiRegioneSiciliana.csv

# rimuovo la stringa 'Gruppo dalla colonna nomeGruppo'
sed -i 's/,Gruppo /,/g' attivitaDeputatiRegioneSiciliana.csv

# faccio pulizia nella cartella corrente
rm ./tmp_*.csv
rm ./PF*.json 
rm ./CF*.json 

# sposto tutto in data
mkdir -p ./data
mv *.json ./data/
mv *.csv ./data/

