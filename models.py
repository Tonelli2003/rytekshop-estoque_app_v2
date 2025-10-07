from app import db

class Endereco(db.Model):
    __tablename__ = 'ENDERECO'
    id_endereco = db.Column(db.Integer, primary_key=True, autoincrement=True)
    cep = db.Column(db.String(10), nullable=False)
    numero = db.Column(db.String(20), nullable=False)
    complemento = db.Column(db.String(100))

class Usuario(db.Model):
    __tablename__ = 'CONTA'
    id_conta = db.Column(db.Integer, primary_key=True, autoincrement=True)
    login = db.Column(db.String(80), nullable=False, unique=True)
    senha = db.Column(db.String(255), nullable=False)
    cargo = db.Column(db.String(20), nullable=False)

class Categoria(db.Model):
    __tablename__ = 'CATEGORIA'
    id_categoria = db.Column(db.Integer, primary_key=True, autoincrement=True)
    nome_categoria = db.Column(db.String(50), nullable=False)

class Pagamento(db.Model):
    __tablename__ = 'PAGAMENTO'
    id_pagamento = db.Column(db.Integer, primary_key=True, autoincrement=True)
    tipo = db.Column(db.String(20), nullable=False)
    parcela = db.Column(db.Integer, default=1)

class Fornecedor(db.Model):
    __tablename__ = 'FORNECEDOR'
    id_fornecedor = db.Column(db.Integer, primary_key=True, autoincrement=True)
    nome = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(200))
    cnpj = db.Column(db.String(18), nullable=False, unique=True)
    telefone = db.Column(db.String(20))
    id_endereco = db.Column(db.Integer, db.ForeignKey('ENDERECO.id_endereco'), nullable=False)
    endereco = db.relationship('Endereco')

class Cliente(db.Model):
    __tablename__ = 'CLIENTE'
    id_cliente = db.Column(db.Integer, primary_key=True, autoincrement=True)
    nome = db.Column(db.String(100), nullable=False)
    cpf = db.Column(db.String(14), nullable=False, unique=True)
    telefone = db.Column(db.String(20), nullable=True) # Corrigido: Campo adicionado
    id_endereco = db.Column(db.Integer, db.ForeignKey('ENDERECO.id_endereco'), nullable=False)
    endereco = db.relationship('Endereco')
    vendas = db.relationship('Venda', back_populates='cliente')

class Estoque(db.Model):
    __tablename__ = 'ESTOQUE'
    id_estoque = db.Column(db.Integer, primary_key=True, autoincrement=True)
    quantidade_produto = db.Column(db.Integer, default=0)
    min_produto = db.Column(db.Integer, default=1)
    last_alert = db.Column(db.DateTime, nullable=True)

class Produto(db.Model):
    __tablename__ = 'PRODUTO'
    id_produto = db.Column(db.Integer, primary_key=True, autoincrement=True)
    nome = db.Column(db.String(200), nullable=False)
    descricao = db.Column(db.Text)
    preco = db.Column(db.Numeric(10, 2), default=0.00)
    preco_promocional = db.Column(db.Numeric(10, 2), nullable=True)
    id_categoria = db.Column(db.Integer, db.ForeignKey('CATEGORIA.id_categoria'), nullable=False)
    fornecedor_id = db.Column(db.Integer, db.ForeignKey('FORNECEDOR.id_fornecedor'))
    estoque_id = db.Column(db.Integer, db.ForeignKey('ESTOQUE.id_estoque'), nullable=False)
    categoria = db.relationship('Categoria')
    fornecedor = db.relationship('Fornecedor')
    estoque = db.relationship('Estoque', uselist=False)

class Venda(db.Model):
    __tablename__ = 'VENDA'
    id_venda = db.Column(db.Integer, primary_key=True, autoincrement=True)
    data_compra = db.Column(db.DateTime, nullable=False)
    valor_total = db.Column(db.Numeric(12, 2), default=0.00)
    id_cliente = db.Column(db.Integer, db.ForeignKey('CLIENTE.id_cliente'), nullable=False)
    id_pagamento = db.Column(db.Integer, db.ForeignKey('PAGAMENTO.id_pagamento'), nullable=False)
    cliente = db.relationship('Cliente', back_populates='vendas')
    pagamento = db.relationship('Pagamento')
    itens = db.relationship('ProdutoVenda', back_populates='venda')

class ProdutoVenda(db.Model):
    __tablename__ = 'PRODUTO_VENDA'
    id_produto = db.Column(db.Integer, db.ForeignKey('PRODUTO.id_produto'), primary_key=True)
    id_venda = db.Column(db.Integer, db.ForeignKey('VENDA.id_venda'), primary_key=True)
    quantidade = db.Column(db.Integer, default=1)
    preco_unitario = db.Column(db.Numeric(10, 2), nullable=False)
    produto = db.relationship('Produto')
    venda = db.relationship('Venda', back_populates='itens')

class PedidoFornecedor(db.Model):
    __tablename__ = 'PEDIDO_FORNECEDOR'
    id_pedido = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_fornecedor = db.Column(db.Integer, db.ForeignKey('FORNECEDOR.id_fornecedor'), nullable=False)
    data_pedido = db.Column(db.DateTime, default=db.func.current_timestamp())
    status = db.Column(db.String(50), default='Pendente')
    fornecedor = db.relationship('Fornecedor')
    itens = db.relationship('PedidoProduto', back_populates='pedido')

class PedidoProduto(db.Model):
    __tablename__ = 'PEDIDO_PRODUTO'
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_pedido = db.Column(db.Integer, db.ForeignKey('PEDIDO_FORNECEDOR.id_pedido'), nullable=False)
    id_produto = db.Column(db.Integer, db.ForeignKey('PRODUTO.id_produto'), nullable=False)
    quantidade_pedida = db.Column(db.Integer, nullable=False)
    pedido = db.relationship('PedidoFornecedor', back_populates='itens')
    produto = db.relationship('Produto')

class Mensagem(db.Model):
    __tablename__ = 'MENSAGEM'
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    fornecedor_id = db.Column(db.Integer, db.ForeignKey('FORNECEDOR.id_fornecedor'))
    produto_id = db.Column(db.Integer, db.ForeignKey('PRODUTO.id_produto'))
    conteudo = db.Column(db.String(2000))
    data_envio = db.Column(db.DateTime, default=db.func.current_timestamp())
    status = db.Column(db.String(50), default='pendente')

class MovimentacaoEstoque(db.Model):
    __tablename__ = 'MOVIMENTACAO_ESTOQUE'
    id_mov = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_produto = db.Column(db.Integer, db.ForeignKey('PRODUTO.id_produto'), nullable=False)
    id_usuario = db.Column(db.Integer, db.ForeignKey('CONTA.id_conta'))
    tipo = db.Column(db.String(50), nullable=False)
    quantidade = db.Column(db.Integer, nullable=False)
    data_movimentacao = db.Column(db.DateTime, default=db.func.current_timestamp())
    observacao = db.Column(db.String(255))
    produto = db.relationship('Produto')
    usuario = db.relationship('Usuario')