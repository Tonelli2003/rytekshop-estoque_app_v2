import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
load_dotenv()
db_url = os.getenv('DATABASE_URL', 'sqlite:///./instance/estoque.db')
engine = create_engine(db_url)
sql_file = os.getenv('RYTEK_SQL_PATH', '/mnt/data/rytekshop_script.sql')
print('Using SQL file:', sql_file)
with open(sql_file, 'r', encoding='utf-8') as f:
    sql = f.read()
# naive split by semicolon
statements = [s.strip() for s in sql.split(';') if s.strip()]
with engine.connect() as conn:
    for st in statements:
        print('Executing statement...')
        try:
            conn.execute(text(st))
        except Exception as e:
            print('Statement failed:', e)
print('Done.')