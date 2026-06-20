# Steam Games SQL Analysis

Analisi SQL del catalogo videoludico di Steam, realizzata come progetto personale per esercitarmi con PostgreSQL e consolidare il mio percorso verso il ruolo di Data Analyst.

## Obiettivo

Esplorare il dataset pubblico di Steam per rispondere a domande di business reali su publisher, sviluppatori, generi, prezzi e valutazioni degli utenti, utilizzando query SQL avanzate (aggregazioni, JOIN, window function, subquery).

## Dataset

**Fonte:** [Steam Store Games](https://www.kaggle.com/datasets/nikdavis/steam-store-games) (Kaggle)

File utilizzati:
- `steam.csv` — ~27.000 giochi con publisher, developer, generi, prezzo, valutazioni e tempo di gioco
- `steamspy_tag_data.csv` — tag della community per ogni gioco

> I file CSV originali non sono inclusi nel repository per dimensioni e licenza. Sono scaricabili liberamente dal link sopra.

## Strumenti utilizzati

- **PostgreSQL** — database relazionale
- **pgAdmin / DBeaver** — gestione e interrogazione del database
- **Python (pandas, SQLAlchemy)** — importazione dei CSV in PostgreSQL

## Contenuto del repository

- `analisi_steam.sql` — tutte le query dell'analisi, commentate, con i risultati e gli insight trovati
- `import_data.py` — script Python usato per importare i CSV originali in PostgreSQL

## Come importare i dati

Prima di eseguire le query è necessario importare i CSV in un database PostgreSQL:

1. Crea un database vuoto (es. `steam_analysis`) in PostgreSQL
2. Installa le dipendenze Python:
   ```
   pip install psycopg2-binary pandas sqlalchemy --break-system-packages
   ```
3. Apri `import_data.py`, sostituisci la password e i percorsi dei file CSV
4. Esegui lo script — crea automaticamente le tabelle `steam` e `steamspy_tags`

## Processo di analisi

Il file `analisi_steam.sql` segue questo percorso:

1. **Esplorazione del dataset** — struttura, conteggio righe, controllo valori nulli
2. **Identificazione valori anomali** — publisher/developer mancanti o scritti come `-`, `none`, `(none)`
3. **Creazione di `steam_clean`** — tabella pulita con publisher e developer principali isolati (alcuni giochi ne avevano fino a 5)
4. **Creazione della vista `steam_genres`** — generi multipli "esplosi" in righe singole con `unnest()`, poiché l'85% dei giochi ha più di un genere
5. **10 domande di analisi**, da semplici aggregazioni a window function (`ROW_NUMBER`, `NTILE`) e subquery

## Domande affrontate

1. Publisher con più di 10 giochi nel catalogo
2. Top 10 sviluppatori per numero di giochi pubblicati
3. Percentuale di valutazioni positive per gioco (top 20 più votati)
4. Differenza di valutazioni tra giochi gratuiti e a pagamento
5. Prezzo medio per genere
6. Relazione tra fascia di prezzo e tempo di gioco medio
7. Playtime medio per genere, incrociato con la fascia di prezzo
8. Miglior rapporto ore di gioco / prezzo pagato
9. Genere dominante per anno di uscita (window function)
10. Publisher con almeno un gioco in top 10% per valutazioni E playtime (NTILE + subquery)

## Risultati principali

- **Big Fish Games** è il publisher con più giochi nel catalogo (213)
- **Choice of Games** è lo sviluppatore più prolifico (94 giochi)
- I giochi **a pagamento** hanno valutazioni medie più alte (81,92%) rispetto ai **gratuiti** (75,22%)
- I generi più costosi su Steam non sono giochi ma **software professionali** (Game Development, Web Publishing)
- I giochi più costosi vengono giocati in media molto più a lungo di quelli economici
- **Action** ha dominato il mercato dal 1997 al 2011; dal 2012 il genere **Indie** è esploso, diventando dominante fino al 2018
- **FINAL FANTASY XIV Online** ha il miglior rapporto ore di gioco / prezzo tra i giochi con oltre 1000 valutazioni
- 78 publisher si distinguono sia per qualità (valutazioni) che per capacità di trattenere i giocatori (playtime)

## Nota metodologica

Per semplificare l'analisi, nei casi di publisher/developer multipli (separati da `;` nel dataset originale) è stato mantenuto solo il primo valore come riferimento principale. I generi, invece, sono stati gestiti tramite una vista dedicata che li esplode tutti, poiché rilevanti per quasi tutte le analisi.

## Nota finale

Questo è il mio primo progetto SQL realizzato in autonomia, senza la guida diretta di un corso. L'obiettivo è stato consolidare la sintassi SQL avanzata (window function, subquery, gestione di dati multi-valore) lavorando su un dataset di mio interesse personale.
