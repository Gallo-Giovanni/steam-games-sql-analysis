"""
Script di importazione dei dataset Steam in PostgreSQL.

Dataset: Steam Store Games (Kaggle) - https://www.kaggle.com/datasets/nikdavis/steam-store-games
File utilizzati: steam.csv, steamspy_tag_data.csv

Prerequisiti:
    pip install psycopg2-binary pandas sqlalchemy --break-system-packages

Prima di eseguire, sostituisci:
    - TUA_PASSWORD con la password del tuo utente PostgreSQL
    - I percorsi dei file CSV con quelli reali sul tuo computer
"""

import pandas as pd
from sqlalchemy import create_engine

# Connessione a PostgreSQL
engine = create_engine('postgresql://postgres:TUA_PASSWORD@localhost:5432/steam_analysis')

# Importa steam.csv -> tabella "steam"
steam = pd.read_csv('PERCORSO/steam.csv')
steam.to_sql('steam', engine, if_exists='replace', index=False)
print("Importato:", len(steam), "righe nella tabella 'steam'")

# Importa steamspy_tag_data.csv -> tabella "steamspy_tags"
tags = pd.read_csv('PERCORSO/steamspy_tag_data.csv')
tags.to_sql('steamspy_tags', engine, if_exists='replace', index=False)
print("Importato:", len(tags), "righe nella tabella 'steamspy_tags'")
