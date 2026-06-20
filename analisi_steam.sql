-- =============================================
-- Steam Games Analysis
-- Autore: Giovanni Gallo
-- Data: giugno 2026
-- Dataset: Steam Store Games (Kaggle) - tabelle steam, steamspy_tags
-- =============================================


-- =============================================
-- DOMANDE DI ANALISI
-- =============================================
-- Mi sono posto qualche domanda prima di iniziare l'analisi dei dati di Steam.
-- Ecco le domande che mi sono posto:
-- 1. Quanti giochi ha ogni publisher nel catalogo? Mostrare solo quelli con più di 10 giochi.
-- 2. Quali sono i 10 sviluppatori con il maggior numero di giochi pubblicati?
-- 3. Qual è la percentuale di valutazioni positive per ogni gioco? Classificare i 20 giochi
--    più votati in assoluto per percentuale positiva.
-- 4. C'è differenza nella percentuale media di valutazioni positive tra giochi gratuiti
--    e giochi a pagamento?
-- 5. Qual è il prezzo medio per genere? Quali generi tendono ad avere giochi più costosi?
-- 6. I giochi più costosi hanno più ore di gioco medie rispetto a quelli economici?
--    Dividere i giochi in fasce di prezzo e confrontare.
-- 7. Quali generi hanno il playtime medio più alto? C'è correlazione con il prezzo?
-- 8. Tra i giochi con più di 1000 valutazioni, quali hanno il rapporto migliore tra
--    ore di gioco e prezzo pagato?
-- 9. Per ogni anno di uscita, qual è il genere dominante per numero di giochi pubblicati?
-- 10. Trova i publisher che hanno almeno un gioco nella top 10% per valutazioni positive
--     e almeno un gioco nella top 10% per playtime medio.


-- =============================================
-- FASE 1: ESPLORAZIONE DEL DATASET
-- =============================================

-- Esploro la struttura e i primi dati delle due tabelle importate
SELECT * 
FROM steam 
LIMIT 10;

SELECT * 
FROM steamspy_tags 
LIMIT 10;

-- Controllo se ci sono appid duplicati (chiave primaria del gioco)
SELECT appid, COUNT(*) AS occorrenze
FROM steam
GROUP BY appid
HAVING COUNT(*) > 1;
-- Nessun duplicato trovato

-- Controllo quali colonne hanno valori nulli o vuoti
SELECT
    COUNT(*) AS totale_righe,
    COUNT(*) FILTER (WHERE appid IS NULL) AS appid_nulli,
    COUNT(*) FILTER (WHERE name IS NULL OR name = '') AS name_nulli,
    COUNT(*) FILTER (WHERE release_date IS NULL OR release_date = '') AS release_date_nulli,
    COUNT(*) FILTER (WHERE english IS NULL) AS english_nulli,
    COUNT(*) FILTER (WHERE developer IS NULL OR developer = '') AS developer_nulli,
    COUNT(*) FILTER (WHERE publisher IS NULL OR publisher = '') AS publisher_nulli,
    COUNT(*) FILTER (WHERE platforms IS NULL OR platforms = '') AS platforms_nulli,
    COUNT(*) FILTER (WHERE required_age IS NULL) AS required_age_nulli,
    COUNT(*) FILTER (WHERE categories IS NULL OR categories = '') AS categories_nulli,
    COUNT(*) FILTER (WHERE genres IS NULL OR genres = '') AS genres_nulli,
    COUNT(*) FILTER (WHERE steamspy_tags IS NULL OR steamspy_tags = '') AS steamspy_tags_nulli,
    COUNT(*) FILTER (WHERE achievements IS NULL) AS achievements_nulli,
    COUNT(*) FILTER (WHERE positive_ratings IS NULL) AS positive_ratings_nulli,
    COUNT(*) FILTER (WHERE negative_ratings IS NULL) AS negative_ratings_nulli,
    COUNT(*) FILTER (WHERE average_playtime IS NULL) AS average_playtime_nulli,
    COUNT(*) FILTER (WHERE median_playtime IS NULL) AS median_playtime_nulli,
    COUNT(*) FILTER (WHERE owners IS NULL OR owners = '') AS owners_nulli,
    COUNT(*) FILTER (WHERE price IS NULL) AS price_nulli
FROM steam;
-- Totale righe: 27.075
-- Valori nulli solo in developer (1) e publisher (14) - colonne importanti per l'analisi,
-- quindi vanno sempre escluse con un filtro nelle query


-- =============================================
-- FASE 2: IDENTIFICAZIONE VALORI ANOMALI
-- =============================================

-- Controllo se in publisher ci sono valori anomali o incompleti oltre ai nulli
SELECT publisher
FROM steam
WHERE publisher IN ('-', '--', 'none', '(none)', ' ')
   OR publisher IS NULL
ORDER BY publisher;
-- Trovati valori anomali: '-', '--', 'none', '(none)', ' '
-- Pattern riutilizzato in tutte le query seguenti per escludere publisher/developer anomali:
--   WHERE publisher NOT IN ('-', '--', 'none', '(none)', ' ') AND publisher IS NOT NULL

-- Noto anche che alcuni publisher contengono due o più publisher separati da ";"
-- probabilmente perché lo stesso gioco viene pubblicato da più publisher insieme.
-- Query esplorativa per capire come "esplodere" i publisher multipli in righe singole
-- (superata in seguito dall'approccio scelto nella tabella steam_clean - vedi sotto):
SELECT
    appid,
    name,
    TRIM(unnest(string_to_array(publisher, ';'))) AS publisher_singolo
FROM steam
WHERE publisher NOT IN ('-', '--', 'none', '(none)', ' ')
AND publisher IS NOT NULL;
-- Risultato: 28.013 righe (contro le 27.075 originali) - confermato il problema dei multi-publisher


-- =============================================
-- FASE 3: CREAZIONE TABELLA PULITA
-- =============================================

-- Essendoci più problemi su diverse colonne, creo una tabella pulita dedicata.
-- Decido di tenere solo il publisher e il developer principali per semplificare l'analisi,
-- non essendo richiesta esplicitamente un'analisi sulla co-pubblicazione.
CREATE TABLE steam_clean AS
SELECT
    appid,
    name,
    release_date,
    english,
    TRIM(SPLIT_PART(developer, ';', 1)) AS developer, -- divido su ; e prendo solo la 1° parte (colonna, divisore, posizione)
    TRIM(SPLIT_PART(publisher, ';', 1)) AS publisher,
    platforms,
    required_age,
    categories,
    genres,
    steamspy_tags,
    achievements,
    positive_ratings,
    negative_ratings,
    average_playtime,
    median_playtime,
    owners,
    price
FROM steam
WHERE publisher NOT IN ('-', '--', 'none', '(none)', ' ')
AND publisher IS NOT NULL
AND developer NOT IN ('-', '--', 'none', '(none)', ' ')
AND developer IS NOT NULL;
-- Tabella creata con 27.045 righe (27.075 originali - 30 righe anomale escluse)


-- =============================================
-- DOMANDA 1: Publisher con più di 10 giochi
-- =============================================

SELECT publisher, COUNT(appid) AS num_giochi
FROM steam_clean
GROUP BY publisher
HAVING COUNT(appid) > 10
ORDER BY num_giochi DESC;

-- Risultato: Big Fish Games è il publisher con più giochi (213)


-- =============================================
-- DOMANDA 2: Top 10 sviluppatori per numero di giochi pubblicati
-- =============================================

SELECT developer, COUNT(appid) AS num_giochi
FROM steam_clean
GROUP BY developer
ORDER BY num_giochi DESC
LIMIT 10;

-- Risultato: Choice of Games è lo sviluppatore con più giochi pubblicati (94),
-- specializzato in giochi narrativi interattivi (interactive fiction)


-- =============================================
-- DOMANDA 3: Percentuale di valutazioni positive per gioco (top 20 più votati)
-- =============================================

-- Prima versione: senza soglia minima di voti, troppi giochi risultano al 100%
-- perché hanno pochissime recensioni totali (es. 1 voto positivo = 100%)
SELECT
    name,
    CAST(positive_ratings AS FLOAT) / (positive_ratings + negative_ratings) * 100 AS valutazioni_positive
FROM steam_clean
ORDER BY valutazioni_positive DESC
LIMIT 20;

-- Versione corretta: aggiungo una soglia minima di 1000 voti totali per risultati affidabili
SELECT
    name,
    positive_ratings + negative_ratings AS totale_voti,
    ROUND(CAST(positive_ratings AS NUMERIC) / (positive_ratings + negative_ratings) * 100, 2) AS valutazioni_positive
FROM steam_clean
WHERE positive_ratings + negative_ratings >= 1000
ORDER BY valutazioni_positive DESC
LIMIT 20;

-- Risultato: 東方天空璋 ～ Hidden Star in Four Seasons, con 4.167 voti totali
-- e il 98,73% di valutazioni positive


-- =============================================
-- DOMANDA 4: Valutazioni positive medie - giochi gratuiti vs a pagamento
-- =============================================

SELECT
    CASE WHEN price = 0 THEN 'Gioco Gratuito' ELSE 'Gioco a Pagamento' END AS tipo,
    ROUND(AVG(CAST(positive_ratings AS NUMERIC) / (positive_ratings + negative_ratings) * 100), 2) AS percentuale_media
FROM steam_clean
WHERE positive_ratings + negative_ratings >= 1000
GROUP BY tipo;

-- Risultato: Gioco a Pagamento 81,92% vs Gioco Gratuito 75,22%
-- I giochi a pagamento hanno una valutazione media più alta, probabilmente perché vengono
-- scelti consapevolmente dall'utente, mentre i giochi gratuiti vengono provati anche da chi
-- non è realmente interessato al genere. Pesano anche le possibili microtransazioni
-- presenti nei giochi free-to-play.


-- =============================================
-- DOMANDA 5: Prezzo medio per genere
-- =============================================

-- Come per developer e publisher, creo una vista dedicata per analizzare i generi,
-- esplodendo la colonna genres (quasi sempre multi-valore) in una riga per genere.
CREATE VIEW steam_genres AS
SELECT
    appid,
    name,
    developer,
    publisher,
    price,
    positive_ratings,
    negative_ratings,
    average_playtime,
    median_playtime,
    owners,
    release_date,
    TRIM(unnest(string_to_array(genres, ';'))) AS genre
FROM steam_clean;

SELECT
    genre,
    ROUND(CAST(AVG(price) AS NUMERIC), 2) AS prezzo_medio
FROM steam_genres
WHERE price != 0 -- escludo i giochi gratuiti per non abbassare la media
GROUP BY genre
ORDER BY prezzo_medio DESC;

-- Risultato: i generi più costosi non sono giochi ma software/strumenti professionali
-- venduti su Steam: Game Development (74,90$) e Web Publishing (55,57$) in testa.
-- I giochi "puri" iniziano a comparire più in basso in classifica (es. Massively Multiplayer, 8,97$)


-- =============================================
-- DOMANDA 6: Playtime medio per fascia di prezzo
-- =============================================

SELECT
    CASE
        WHEN price = 0 THEN 'Gratuito'
        WHEN price <= 10 THEN 'Economico'
        WHEN price <= 40 THEN 'Medio'
        ELSE 'Costoso'
    END AS fascia_prezzo,
    ROUND(AVG(average_playtime)::numeric / 60, 2) AS playtime_medio_ore
FROM steam_clean
WHERE average_playtime > 0 -- escludo i giochi senza dati di playtime registrati
GROUP BY fascia_prezzo
ORDER BY playtime_medio_ore DESC;

-- Risultato: i giochi più costosi vengono giocati in media più a lungo, probabilmente per
-- la maggiore quantità di contenuti rispetto ai giochi economici. I giochi gratuiti sono
-- al secondo posto: spesso sono MMO con microtransazioni che offrono centinaia di ore di gioco.


-- =============================================
-- DOMANDA 7: Playtime medio per genere, incrociato con la fascia di prezzo
-- =============================================

-- Riutilizzo la logica delle fasce di prezzo della domanda 6, aggiungendo il genere
SELECT
    CASE
        WHEN price = 0 THEN 'Gratuito'
        WHEN price <= 10 THEN 'Economico'
        WHEN price <= 40 THEN 'Medio'
        ELSE 'Costoso'
    END AS fascia_prezzo,
    genre,
    ROUND(AVG(average_playtime)::numeric / 60, 2) AS playtime_medio_ore
FROM steam_genres
WHERE average_playtime > 0
GROUP BY fascia_prezzo, genre
ORDER BY genre DESC;

-- Risultato: in quasi tutti i generi la fascia "Costoso" mostra il playtime medio più alto
-- (es. Utilities 15,75h, Web Publishing 10,94h, Violent 8,42h), mentre la fascia "Gratuito"
-- tende ad avere i valori più bassi. Questo conferma la tendenza già vista nella domanda 6:
-- il prezzo più alto è associato a un maggiore tempo di gioco, indipendentemente dal genere.


-- =============================================
-- DOMANDA 8: Miglior rapporto ore di gioco / prezzo (giochi con >1000 valutazioni)
-- =============================================

-- Filtro solo giochi con almeno 1000 valutazioni totali e a pagamento (price > 0,
-- per evitare la divisione per zero), poi calcolo le ore di gioco per ogni unità di prezzo
SELECT
    name,
    positive_ratings + negative_ratings AS totale_voti,
    ROUND((average_playtime::numeric / 60 / price::numeric), 2) AS ore_per_euro
FROM steam_clean
WHERE positive_ratings + negative_ratings >= 1000 AND price > 0
ORDER BY ore_per_euro DESC;

-- Risultato: FINAL FANTASY XIV Online ha il miglior rapporto, con circa 48 ore di gioco
-- per ogni euro speso (11.915 voti totali). Ha senso trattandosi di un MMORPG ad abbonamento,
-- dove il costo iniziale è basso rispetto alle centinaia di ore di contenuto offerte nel tempo.


-- =============================================
-- DOMANDA 9: Genere dominante per anno di uscita
-- =============================================

-- Uso una window function per estrarre, per ogni anno, solo il genere con più giochi pubblicati
SELECT *
FROM (
    SELECT
        EXTRACT(YEAR FROM release_date::date) AS anno, -- converto release_date in date ed estraggo l'anno
        genre,
        COUNT(*) AS num_giochi,
        ROW_NUMBER() OVER (
            PARTITION BY EXTRACT(YEAR FROM release_date::date)
            ORDER BY COUNT(*) DESC
        ) AS rn -- numero le righe per anno, dal genere più pubblicato (rn = 1) al meno pubblicato
    FROM steam_genres
    GROUP BY EXTRACT(YEAR FROM release_date::date), genre
) AS sub
WHERE rn = 1
ORDER BY anno;

-- Nota tecnica: con PostgreSQL devo ripetere EXTRACT(YEAR FROM release_date::date) invece di
-- usare l'alias "anno", perché tutte le espressioni nel SELECT vengono calcolate allo stesso
-- livello, non in sequenza. L'alias "anno" diventa utilizzabile solo DOPO che il SELECT è
-- completo (es. nell'ORDER BY esterno), non all'interno dello stesso SELECT/PARTITION BY.

-- Risultato: "Action" è il genere dominante dal 1997 al 2011. Dal 2012 il testimone passa
-- a "Indie", che cresce in modo esplosivo fino al 2018 (da 167 a 6.396 giochi dominanti
-- nell'anno) - riflettendo la crescita della scena indipendente su Steam, probabilmente
-- legata alla maggiore accessibilità della piattaforma per piccoli sviluppatori in quegli anni.


-- =============================================
-- DOMANDA 10: Publisher con almeno un gioco in top 10% per rating E playtime
-- =============================================

-- Uso NTILE(10) per dividere i giochi in 10 fasce (decili) in base a valutazioni e playtime.
-- Il decile 1 rappresenta il top 10% per quella metrica.
SELECT
    publisher,
    COUNT(*) FILTER (WHERE top_10_rating = 1) AS cont1,
    COUNT(*) FILTER (WHERE top_10_playtime = 1) AS cont2
FROM (
    SELECT
        publisher,
        positive_ratings + negative_ratings AS totale_voti,
        NTILE(10) OVER (ORDER BY positive_ratings DESC) AS top_10_rating,
        NTILE(10) OVER (ORDER BY average_playtime DESC) AS top_10_playtime
    FROM steam_clean
    WHERE positive_ratings + negative_ratings >= 1000
) AS sub
GROUP BY publisher
HAVING COUNT(*) FILTER (WHERE top_10_rating = 1) > 0
   AND COUNT(*) FILTER (WHERE top_10_playtime = 1) > 0
ORDER BY cont1 DESC, cont2 DESC;

-- Nota tecnica: stesso principio della domanda 9 - HAVING viene eseguito prima del SELECT
-- nell'ordine di esecuzione di PostgreSQL, quindi gli alias "cont1"/"cont2" non sono ancora
-- disponibili in quel punto e vanno ripetute le espressioni complete con COUNT(*) FILTER(...).

-- Risultato: 78 publisher soddisfano entrambe le condizioni - un gruppo selettivo che ha
-- dimostrato eccellenza sia in qualità (valutazioni positive) che in capacità di
-- mantenere impegnati i giocatori nel tempo (playtime).