from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from sqlalchemy import Column, Integer, String, Numeric, ForeignKey, DateTime, Date
from sqlalchemy.orm import relationship
from app import db

class Endereco(db.Model):
    __tablename__ = 'ENDERECO'
    id_endereco = Column(Integer, primary_key=True)
    cep = Column(String(10), nullable=False)
    numero = Column(String(8), nullable=False)
    complemento = Column(String(100))

class Usuario(db.Model):
    __tablename__ = 'CONTA'
    id_conta = Column(Integer, primary_key=True)
    login = Column(String(80), unique=True, nullable=False)
    senha = Column(String(255), nullable=False)
    cargo = Column(String(20), nullable=False)

class Fornecedor(db.Model):
    __tablename__ = 'FORNECEDOR'
    id_fornecedor = Column(Integer, primary_key=True)
    nome = Column(String(120), nullable=False)
    email = Column(String(200))
    cnpj = Column(String(18), unique=True, nullable=False)
    telefone = Column(String(20))
    id_endereco = Column(Integer, ForeignKey('ENDERECO.id_endereco'), nullable=False)

class Estoque(db.Model):
    __tablename__ = 'ESTOQUE'
    id_estoque = Column(Integer, primary_key=True)
    quantidade_produto = Column(Integer, default=0)
    min_produto = Column(Integer, default=1)
    last_alert = Column(DateTime, nullable=True)

class Categoria(db.Model):
    __tablename__ = 'CATEGORIA'
    id_categoria = Column(Integer, primary_key=True)
    nome_categoria = Column(String(50), nullable=False)

class Produto(db.Model):
    __tablename__ = 'PRODUTO'
    id_produto = Column(Integer, primary_key=True)
    nome = Column(String(200), nullable=False)
    descricao = Column(String(1000))
    preco = Column(Numeric(10,2), default=0.0)
    preco_promocional = Column(Numeric(10,2), nullable=True)
    id_categoria = Column(Integer, ForeignKey('CATEGORIA.id_categoria'), nullable=False)
    fornecedor_id = Column(Integer, ForeignKey('FORNECEDOR.id_fornecedor'))
    estoque_id = Column(Integer, ForeignKey('ESTOQUE.id_estoque'))
    fornecedor = relationship('Fornecedor', backref='produtos')
    estoque = relationship('Estoque', backref='produto_rel')

class Cliente(db.Model):
    __tablename__ = 'CLIENTE'
    id_cliente = Column(Integer, primary_key=True)
    nome = Column(String(100), nullable=False)
    cpf = Column(String(14), unique=True, nullable=False)
    id_endereco = Column(Integer, ForeignKey('ENDERECO.id_endereco'), nullable=False)
    vendas = relationship('Venda', back_populates='cliente')

class Pagamento(db.Model):
    __tablename__ = 'PAGAMENTO'
    id_pagamento = Column(Integer, primary_key=True)
    tipo = Column(String(20), nullable=False)
    parcela = Column(Integer, default=1)

class Venda(db.Model):
    __tablename__ = 'VENDA'
    id_venda = Column(Integer, primary_key=True)
    data_compra = Column(Date, default=datetime.utcnow)
    valor_total = Column(Numeric(12,2), default=0.0)
    id_cliente = Column(Integer, ForeignKey('CLIENTE.id_cliente'), nullable=False)
    id_pagamento = Column(Integer, ForeignKey('PAGAMENTO.id_pagamento'), nullable=False)
    cliente = relationship('Cliente', back_populates='vendas')
    itens = relationship('ProdutoVenda', back_populates='venda')

class ProdutoVenda(db.Model):
    __tablename__ = 'PRODUTO_VENDA'
    id_produto = Column(Integer, ForeignKey('PRODUTO.id_produto'), primary_key=True)
    id_venda = Column(Integer, ForeignKey('VENDA.id_venda'), primary_key=True)
    quantidade = Column(Integer, default=1)
    preco_unitario = Column(Numeric(10,2), nullable=False)
    venda = relationship('Venda', back_populates='itens')
    produto = relationship('Produto')

class Mensagem(db.Model):
    __tablename__ = 'MENSAGEM'
    id = Column(Integer, primary_key=True)
    fornecedor_id = Column(Integer, ForeignKey('FORNECEDOR.id_fornecedor'))
    produto_id = Column(Integer, ForeignKey('PRODUTO.id_produto'))
    conteudo = Column(String(2000))
    data_envio = Column(DateTime, default=datetime.utcnow)
    status = Column(String(50), default='pendente')

class PedidoFornecedor(db.Model):
    __tablename__ = 'PEDIDO_FORNECEDOR'
    id_pedido = Column(Integer, primary_key=True)
    id_fornecedor = Column(Integer, ForeignKey('FORNECEDOR.id_fornecedor'), nullable=False)
    data_pedido = Column(DateTime, default=datetime.utcnow)
    status = Column(String(50), default='Pendente')
    fornecedor = relationship('Fornecedor')
    itens = relationship('PedidoProduto', back_populates='pedido', cascade="all, delete-orphan")

class PedidoProduto(db.Model):
    __tablename__ = 'PEDIDO_PRODUTO'
    id = Column(Integer, primary_key=True)
    id_pedido = Column(Integer, ForeignKey('PEDIDO_FORNECEDOR.id_pedido'), nullable=False)
    id_produto = Column(Integer, ForeignKey('PRODUTO.id_produto'), nullable=False)
    quantidade_pedida = Column(Integer, nullable=False)
    pedido = relationship('PedidoFornecedor', back_populates='itens')
    produto = relationship('Produto')

class MovimentacaoEstoque(db.Model):
    __tablename__ = 'MOVIMENTACAO_ESTOQUE'
    id_mov = Column(Integer, primary_key=True)
    id_produto = Column(Integer, ForeignKey('PRODUTO.id_produto'), nullable=False)
    id_usuario = Column(Integer, ForeignKey('CONTA.id_conta'), nullable=True)
    tipo = Column(String(50), nullable=False)
    quantidade = Column(Integer, nullable=False)
    data_movimentacao = Column(DateTime, default=datetime.utcnow)
    observacao = Column(String(255))
    produto = relationship('Produto')
    usuario = relationship('Usuario')