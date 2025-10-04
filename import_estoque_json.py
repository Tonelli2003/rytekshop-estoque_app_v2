import os, json
from dotenv import load_dotenv
load_dotenv()

from app import db, seed_data
from models import Fornecedor, Estoque, Produto

# path to user-provided estoque.json (uploaded earlier)
json_path = os.getenv('ESTOQUE_JSON_PATH', '/mnt/data/estoque.json')
print('Loading', json_path)
with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Ensure DB initialized and seed minimal data
seed_data()

for item in data.get('produtos', data if isinstance(data, list) else []):
    nome = item.get('nome') or item.get('name') or item.get('produto')
    if not nome: continue
    # find or create fornecedor
    forn_name = item.get('fornecedor') or 'Fornecedor'
    forn = Fornecedor.query.filter_by(nome=forn_name).first()
    if not forn:
        forn = Fornecedor(nome=forn_name, email=item.get('fornecedor_email') or None)
        db.session.add(forn); db.session.flush()
    # create estoque and produto
    est = Estoque(quantidade=int(item.get('quantidade',0)), min_produto=int(item.get('min_produto',1)))
    db.session.add(est); db.session.flush()
    p = Produto(nome=nome, descricao=item.get('descricao'), preco=float(item.get('preco',0.0)), fornecedor_id=forn.id_fornecedor, estoque_id=est.id_estoque)
    db.session.add(p)
db.session.commit()
print('Import finished.')