# Assemblea Regionale Siciliana numbers

Il 17 ottobre 2017 Cristiano Longo ha scritto nella [mailing list](https://groups.google.com/forum/#!msg/opendatasicilia/_ea_10o1xkI/oMatwmmYAQAJ) di OpenDataSicilia che [**Generazione Y/Diritto di Accesso**](http://dirittodiaccesso.eu) si è occupata di fare un faticoso lavoro redazionale per monitorare le attività dei deputati dell'[Assemblea Regionale Siciliana](http://www.ars.sicilia.it/deputati/gruppi.jsp). Ne è nato un report in formato aperto pubblicato su [opendatahacklab](http://www.opendatahacklab.org/site/dataset/monitoraggiosicilia2017/).

Il report contiene i **numeri** sulle attività parlamentari delle deputate e dei deputati da primi firmatari e/o cofirmatari.

Abbiamo creato uno [script](./assembleaSicilianaNumbers.sh) in BASH, che estrae questi dati in automatico e produce i seguenti file:

- [cofirmatario.csv](https://github.com/ondata/assemblearegionalesiciliana_numbers/blob/master/data/cofirmatario.csv), con i dati di deputate e deputati da confirmatarie/i in formato CSV;
- [cofirmatario.json](https://github.com/ondata/assemblearegionalesiciliana_numbers/blob/master/data/cofirmatario.json), con i dati di deputate e deputati da confirmatarie/i in formato JSON;
- [primofirmatario.csv](https://github.com/ondata/assemblearegionalesiciliana_numbers/blob/master/data/primofirmatario.csv), con i dati di deputate e deputati da prime/i firmatarie/i in formato CSV;
- [primofirmatario.json](https://github.com/ondata/assemblearegionalesiciliana_numbers/blob/master/data/primofirmatario.json), con i dati di deputate e deputati da prime/i firmatarie/i in formato JSON;
- [attivitaDeputatiRegioneSiciliana.csv](https://github.com/ondata/assemblearegionalesiciliana_numbers/blob/master/data/attivitaDeputatiRegioneSiciliana.csv), con tutti i dati aggregati in formato CSV secondo lo schema di sotto.

| idDeputato | idGruppo | DisegnidiLegge | InterrogazioniParlamentari | InterpellanzeParlamentari | Mozioni | Ordinidelgiorno | DisegnidiLegge_co | InterrogazioniParlamentari_co | InterpellanzeParlamentari_co | Mozioni_co | Ordinidelgiorno_co | uriDeputato                                                             | nome                    | collegio | nomeGruppo                      | 
|------------|----------|----------------|----------------------------|---------------------------|---------|-----------------|-------------------|-------------------------------|------------------------------|------------|--------------------|-------------------------------------------------------------------------|-------------------------|----------|---------------------------------| 
| 32         | 196      | 11             | 13                         | 1                         | 2       | 2               | 19                | 2                             | 1                            | 8          | 12                 | http://www.ars.sicilia.it/deputati/scheda.jsp?idLegis=16&idDeputato=32  | On. Cracolici Antonello | Palermo  | Gruppo Partito Democratico (PD) | 
| 692        | 196      | 14             | 5                          | 1                         | 3       | 2               | 18                | 0                             | 1                            | 14         | 8                  | http://www.ars.sicilia.it/deputati/scheda.jsp?idLegis=16&idDeputato=692 | On. Laccoto Giuseppe    | Messina  | Gruppo Partito Democratico (PD) | 
| 695        | 196      | 2              | 10                         | 0                         | 1       | 4               | 1                 | 0                             | 0                            | 0          | 4                  | http://www.ars.sicilia.it/deputati/scheda.jsp?idLegis=16&idDeputato=695 | On. Apprendi Giuseppe   | Palermo  | Gruppo Partito Democratico (PD) | 
| …          | …        | …              | …                          | …                         | …       | …               | …                 | …                             | …                            | …          | …                  | …                                                                       | …                       | …        | …                               | 


## Note

Tutti i CSV sono in `UTF-8` e hanno la `,` come separatore.
<br>Manca ancora una descrizione dello schema dati.

È uno script basato su:

- csvkit [https://csvkit.readthedocs.io](https://csvkit.readthedocs.io);
- jq [https://stedolan.github.io/jq/](https://stedolan.github.io/jq/);
- pup [https://github.com/ericchiang/pup](https://github.com/ericchiang/pup)
- scrape [https://github.com/jeroenjanssens/data-science-at-the-command-line/blob/master/tools/scrape](https://github.com/jeroenjanssens/data-science-at-the-command-line/blob/master/tools/scrape);
- xml2json [https://github.com/Inist-CNRS/node-xml2json-command](https://github.com/Inist-CNRS/node-xml2json-command).