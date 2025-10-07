import os, io, json
from flask import Flask, render_template, request, redirect, session, url_for, jsonify, flash, send_file
import pandas as pd
from io import BytesIO
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.orm import joinedload
from sqlalchemy import func, not_
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime, timedelta
from dotenv import load_dotenv
import click

# Carrega as variáveis do arquivo .env
load_dotenv()

app = Flask(__name__)

# Configuração para ler as variáveis de ambiente
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY')
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# Importa os modelos após a inicialização do 'db'
from models import (Usuario, Fornecedor, Estoque, Produto, Venda, Categoria, 
                    Endereco, Mensagem, Cliente, Pagamento, ProdutoVenda,
                    PedidoFornecedor, PedidoProduto, MovimentacaoEstoque)


# =======================================================================
# FUNÇÕES AUXILIARES
# =======================================================================

def valida_cpf(cpf: str) -> bool:
    """Valida um CPF brasileiro."""
    cpf = ''.join(filter(str.isdigit, cpf))
    if len(cpf) != 11 or cpf == cpf[0] * 11:
        return False
    soma = sum(int(cpf[i]) * (10 - i) for i in range(9))
    resto = (soma * 10) % 11
    if resto == 10: resto = 0
    if resto != int(cpf[9]): return False
    soma = sum(int(cpf[i]) * (11 - i) for i in range(10))
    resto = (soma * 10) % 11
    if resto == 10: resto = 0
    if resto != int(cpf[10]): return False
    return True

def seed_essentials():
    """
    Verifica se os usuários essenciais (admin, seller) existem e garante que
    suas senhas estejam corretamente criptografadas.
    """
    print("Verificando e atualizando senhas dos usuários essenciais...")
    try:
        admin_user = Usuario.query.filter_by(login='admin').first()
        if admin_user:
            admin_user.senha = generate_password_hash('admin')
            print("Senha do 'admin' atualizada.")
        else:
            admin_user = Usuario(login='admin', senha=generate_password_hash('admin'), cargo='GERENTE')
            db.session.add(admin_user)
            print("Usuário 'admin' criado.")

        seller_user = Usuario.query.filter_by(login='seller').first()
        if seller_user:
            seller_user.senha = generate_password_hash('seller')
            print("Senha do 'seller' atualizada.")
        else:
            seller_user = Usuario(login='seller', senha=generate_password_hash('seller'), cargo='VENDEDOR')
            db.session.add(seller_user)
            print("Usuário 'seller' criado.")
            
        db.session.commit()
        print("Usuários essenciais verificados/atualizados com sucesso.")
    except Exception as e:
        db.session.rollback()
        print(f"ERRO ao atualizar senhas: {e}")


# --- Rotas ---
@app.route('/login', methods=['GET','POST'])
def login():
    if request.method=='POST':
        login_ = request.form.get('login')
        senha = request.form.get('senha')
        user = Usuario.query.filter_by(login=login_).first()
        if user and check_password_hash(user.senha, senha):
            session['user_id'] = user.id_conta
            session['cargo'] = user.cargo
            session['login'] = user.login
            return redirect(url_for('index'))
        flash('Credenciais inválidas','danger')
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        login = request.form.get('login')
        senha = request.form.get('senha')
        user_exists = Usuario.query.filter_by(login=login).first()
        if user_exists:
            flash('Este nome de usuário já está em uso. Por favor, escolha outro.', 'danger')
            return redirect(url_for('register'))
        novo_usuario = Usuario(login=login, senha=generate_password_hash(senha), cargo='VENDEDOR')
        db.session.add(novo_usuario)
        db.session.commit()
        flash('Conta criada com sucesso! Por favor, faça o login.', 'success')
        return redirect(url_for('login'))
    return render_template('register.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

@app.route('/')
def index():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    if session.get('cargo') == 'GERENTE':
        return redirect(url_for('dashboard'))
    return redirect(url_for('vendas'))

@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session or session.get('cargo') != 'GERENTE':
        return redirect(url_for('login'))

    hoje = datetime.utcnow()
    noventa_dias_atras = hoje - timedelta(days=90)
    subquery_recentes = db.session.query(ProdutoVenda.id_produto).join(Venda).filter(
        Venda.data_compra >= noventa_dias_atras
    ).distinct().subquery()
    produtos_parados = db.session.query(Produto).outerjoin(
        subquery_recentes, Produto.id_produto == subquery_recentes.c.id_produto
    ).filter(subquery_recentes.c.id_produto == None).all()

    total_vendas = db.session.query(func.sum(Venda.valor_total)).scalar() or 0
    total_produtos_estoque = db.session.query(func.sum(Estoque.quantidade_produto)).scalar() or 0
    
    return render_template(
        'dashboard.html', 
        user=session.get('login'),
        total_vendas=total_vendas,
        total_produtos_estoque=total_produtos_estoque,
        produtos_parados=produtos_parados
    )

@app.route('/estoque')
def estoque():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    query = request.args.get('q')
    produtos_query = Produto.query.order_by(Produto.nome)
    if query:
        produtos_query = produtos_query.filter(Produto.nome.ilike(f'%{query}%'))
    produtos = produtos_query.all()
    
    produtos_estoque_baixo = db.session.query(Produto).join(Estoque).filter(
        Estoque.quantidade_produto <= 5
    ).all()

    return render_template('estoque.html', 
                           produtos=produtos, 
                           cargo=session.get('cargo'), 
                           search_query=query,
                           produtos_estoque_baixo=produtos_estoque_baixo)

@app.route('/mensagens')
def mensagens():
    if 'user_id' not in session or session.get('cargo') != 'GERENTE':
        return redirect(url_for('login'))
    msgs = Mensagem.query.order_by(Mensagem.data_envio.desc()).all()
    return render_template('mensagens.html', mensagens=msgs)

@app.route('/contatar_fornecedor/<int:id_produto>', methods=['GET', 'POST'])
def contatar_fornecedor(id_produto):
    if 'user_id' not in session:
        return redirect(url_for('login'))
    produto = Produto.query.get_or_404(id_produto)
    if not produto.fornecedor:
        flash('Este produto não tem um fornecedor associado.', 'warning')
        return redirect(url_for('estoque'))
    if request.method == 'POST':
        quantidade = request.form.get('quantidade')
        mensagem_adicional = request.form.get('mensagem')
        if not quantidade or int(quantidade) <= 0:
            flash('A quantidade deve ser um número maior que zero.', 'danger')
            return render_template('contatar_fornecedor.html', produto=produto)
        try:
            novo_pedido_obj = PedidoFornecedor(id_fornecedor=produto.fornecedor_id, status='Pendente')
            db.session.add(novo_pedido_obj)
            db.session.flush()
            item_pedido = PedidoProduto(id_pedido=novo_pedido_obj.id_pedido, id_produto=produto.id_produto, quantidade_pedida=int(quantidade))
            db.session.add(item_pedido)
            conteudo_log = f"Pedido de reposição para '{produto.nome}' (Qtd: {quantidade}) criado. Mensagem adicional: {mensagem_adicional or 'Nenhuma'}"
            nova_mensagem = Mensagem(fornecedor_id=produto.fornecedor_id, produto_id=produto.id_produto, conteudo=conteudo_log, status='LOG do Sistema')
            db.session.add(nova_mensagem)
            db.session.commit()
            flash(f'Pedido de reposição para "{produto.nome}" criado com sucesso!', 'success')
            return redirect(url_for('pedidos'))
        except Exception as e:
            db.session.rollback()
            flash(f'Ocorreu um erro ao criar o pedido: {e}', 'danger')
    return render_template('contatar_fornecedor.html', produto=produto)

@app.route('/produto/novo', methods=['GET', 'POST'])
def novo_produto():
    if 'user_id' not in session or session.get('cargo') != 'GERENTE':
        return redirect(url_for('login'))
    if request.method == 'POST':
        nome = request.form.get('nome')
        descricao = request.form.get('descricao')
        preco = request.form.get('preco')
        quantidade = request.form.get('quantidade')
        if not nome or not preco or not quantidade:
            flash('Todos os campos são obrigatórios.', 'danger')
            return render_template('produto_form.html', title='Adicionar Novo Produto')
        novo_estoque = Estoque(quantidade_produto=int(quantidade), min_produto=1)
        db.session.add(novo_estoque)
        db.session.flush()
        fornecedor_padrao = Fornecedor.query.first()
        categoria_padrao = Categoria.query.first()
        novo_prod = Produto(nome=nome, descricao=descricao, preco=float(preco), estoque_id=novo_estoque.id_estoque, fornecedor_id=fornecedor_padrao.id_fornecedor, id_categoria=categoria_padrao.id_categoria)
        db.session.add(novo_prod)
        db.session.commit()
        flash('Produto adicionado com sucesso!', 'success')
        return redirect(url_for('estoque'))
    return render_template('produto_form.html', title='Adicionar Novo Produto')

@app.route('/produto/<int:id_produto>/editar', methods=['GET', 'POST'])
def editar_produto(id_produto):
    if 'user_id' not in session:
        return redirect(url_for('login'))
    produto = Produto.query.get_or_404(id_produto)
    if request.method == 'POST':
        produto.nome = request.form.get('nome')
        produto.descricao = request.form.get('descricao')
        produto.preco = float(request.form.get('preco'))
        db.session.commit()
        flash('Produto atualizado com sucesso!', 'success')
        return redirect(url_for('estoque'))
    return render_template('produto_form.html', title='Editar Produto', produto=produto)

@app.route('/produto/<int:id_produto>/promocao', methods=['GET', 'POST'])
def criar_promocao(id_produto):
    if 'user_id' not in session or session.get('cargo') != 'GERENTE':
        return redirect(url_for('login'))
    produto = Produto.query.get_or_404(id_produto)
    if request.method == 'POST':
        novo_preco_str = request.form.get('preco_promocional')
        if novo_preco_str and float(novo_preco_str) > 0:
            produto.preco_promocional = float(novo_preco_str)
            flash(f'Promoção para "{produto.nome}" criada com sucesso!', 'success')
        else:
            produto.preco_promocional = None
            flash(f'Promoção para "{produto.nome}" removida.', 'info')
        db.session.commit()
        return redirect(url_for('dashboard'))
    return render_template('promocao_form.html', produto=produto)

@app.route('/pedidos')
def pedidos():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    lista_pedidos = PedidoFornecedor.query.order_by(PedidoFornecedor.data_pedido.desc()).all()
    return render_template('pedidos.html', pedidos=lista_pedidos)

@app.route('/pedidos/novo', methods=['GET', 'POST'])
def novo_pedido():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    if request.method == 'POST':
        id_fornecedor = request.form.get('fornecedor')
        produtos_ids = request.form.getlist('produto_id[]')
        quantidades = request.form.getlist('quantidade[]')
        if not id_fornecedor or not produtos_ids:
            flash('Selecione um fornecedor e adicione ao menos um produto.', 'warning')
            fornecedores = Fornecedor.query.order_by(Fornecedor.nome).all()
            produtos = Produto.query.order_by(Produto.nome).all()
            return render_template('novo_pedido.html', fornecedores=fornecedores, produtos=produtos)
        novo_pedido_obj = PedidoFornecedor(id_fornecedor=id_fornecedor)
        db.session.add(novo_pedido_obj)
        db.session.flush()
        itens_para_msg = []
        for pid, qty in zip(produtos_ids, quantidades):
            if pid and qty and int(qty) > 0:
                item_pedido = PedidoProduto(pedido=novo_pedido_obj, id_produto=int(pid), quantidade_pedida=int(qty))
                db.session.add(item_pedido)
                produto_nome = Produto.query.get(int(pid)).nome
                itens_para_msg.append(f"{produto_nome} ({qty} un)")
        conteudo_msg = f"Pedido #{novo_pedido_obj.id_pedido} criado. Itens: {', '.join(itens_para_msg)}."
        nova_mensagem = Mensagem(fornecedor_id=id_fornecedor, conteudo=conteudo_msg, status='LOG do Sistema')
        db.session.add(nova_mensagem)
        db.session.commit()
        flash('Novo pedido criado com sucesso!', 'success')
        return redirect(url_for('pedidos'))
    fornecedores = Fornecedor.query.order_by(Fornecedor.nome).all()
    produtos = Produto.query.order_by(Produto.nome).all()
    return render_template('novo_pedido.html', fornecedores=fornecedores, produtos=produtos)

@app.route('/pedidos/<int:id_pedido>/receber', methods=['GET', 'POST'])
def receber_pedido(id_pedido):
    if 'user_id' not in session:
        return redirect(url_for('login'))
    pedido = PedidoFornecedor.query.get_or_404(id_pedido)
    if pedido.status != 'Pendente':
        flash('Este pedido já foi processado.', 'info')
        return redirect(url_for('pedidos'))
    if request.method == 'POST':
        try:
            for item in pedido.itens:
                quantidade_recebida = int(request.form.get(f'qty_{item.id_produto}'))
                if quantidade_recebida >= 0 and item.produto.estoque:
                    item.produto.estoque.quantidade_produto += quantidade_recebida
                    mov = MovimentacaoEstoque(id_produto=item.id_produto, id_usuario=session.get('user_id'), tipo='ENTRADA', quantidade=quantidade_recebida, observacao=f'Recebimento do Pedido #{pedido.id_pedido}')
                    db.session.add(mov)
            pedido.status = 'Recebido'
            db.session.commit()
            flash(f'Estoque atualizado com sucesso a partir do pedido #{pedido.id_pedido}!', 'success')
            return redirect(url_for('pedidos'))
        except Exception as e:
            db.session.rollback()
            flash(f'Ocorreu um erro ao processar o recebimento: {e}', 'danger')
    return render_template('receber_pedido.html', pedido=pedido)

@app.route('/vendas')
def vendas():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    lista_vendas = db.session.query(Venda).options(joinedload(Venda.cliente), joinedload(Venda.itens)).order_by(Venda.data_compra.desc()).all()
    return render_template('vendas.html', vendas=lista_vendas)

@app.route('/venda/<int:id_venda>')
def venda_detalhes(id_venda):
    if 'user_id' not in session:
        return redirect(url_for('login'))
    venda = db.session.query(Venda).options(joinedload(Venda.cliente), joinedload(Venda.itens).joinedload(ProdutoVenda.produto)).get(id_venda)
    if not venda:
        flash('Venda não encontrada.', 'danger')
        return redirect(url_for('vendas'))
    return render_template('venda_detalhes.html', venda=venda)

@app.route('/venda/<int:id_venda>/recibo')
def recibo_venda(id_venda):
    if 'user_id' not in session:
        return redirect(url_for('login'))
    venda = db.session.query(Venda).options(joinedload(Venda.cliente), joinedload(Venda.itens).joinedload(ProdutoVenda.produto)).get(id_venda)
    if not venda:
        flash('Venda não encontrada.', 'danger')
        return redirect(url_for('vendas'))
    return render_template('recibo.html', venda=venda)

@app.route('/vendas/nova', methods=['GET', 'POST'])
def nova_venda():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    if request.method == 'POST':
        id_cliente_selecionado = request.form.get('id_cliente_selecionado')
        if not id_cliente_selecionado:
            flash('Nenhum cliente selecionado. Por favor, pesquise por CPF/Nome ou cadastre um novo cliente.', 'danger')
            return redirect(url_for('nova_venda'))

        produtos_ids = request.form.getlist('produto_id[]')
        quantidades = request.form.getlist('quantidade[]')
        
        if not produtos_ids or not any(q and q.isdigit() and int(q) > 0 for q in quantidades):
            flash('Adicione ao menos um produto com quantidade maior que zero.', 'warning')
            return redirect(url_for('nova_venda'))

        valor_total_venda = 0
        itens_da_venda = []
        
        for pid, qty_str in zip(produtos_ids, quantidades):
            if not (pid and qty_str and qty_str.isdigit() and int(qty_str) > 0):
                continue
            
            qty = int(qty_str)
            produto = Produto.query.get(int(pid))
            
            if produto.estoque.quantidade_produto < qty:
                flash(f'Estoque insuficiente para "{produto.nome}". Disponível: {produto.estoque.quantidade_produto}', 'danger')
                return redirect(url_for('nova_venda'))

            preco_a_cobrar = produto.preco_promocional if produto.preco_promocional else produto.preco
            valor_total_venda += float(preco_a_cobrar) * qty
            itens_da_venda.append({'produto': produto, 'quantidade': qty, 'preco_unitario': preco_a_cobrar})

        try:
            pagamento_padrao = Pagamento.query.first()
            
            nova_venda_obj = Venda(
                id_cliente=id_cliente_selecionado, 
                id_pagamento=pagamento_padrao.id_pagamento, 
                valor_total=valor_total_venda,
                data_compra=datetime.utcnow()
            )
            db.session.add(nova_venda_obj)
            db.session.flush()

            for item in itens_da_venda:
                produto = item['produto']
                quantidade_vendida = item['quantidade']
                
                produto_venda_link = ProdutoVenda(
                    id_venda=nova_venda_obj.id_venda, 
                    id_produto=produto.id_produto, 
                    quantidade=quantidade_vendida,
                    preco_unitario=item['preco_unitario']
                )
                db.session.add(produto_venda_link)
                
                produto.estoque.quantidade_produto -= quantidade_vendida
                
                mov = MovimentacaoEstoque(
                    id_produto=produto.id_produto, 
                    id_usuario=session.get('user_id'), 
                    tipo='SAÍDA', 
                    quantidade=quantidade_vendida,
                    observacao=f'Venda #{nova_venda_obj.id_venda}'
                )
                db.session.add(mov)

            db.session.commit()
            flash('Venda registrada com sucesso!', 'success')
            return redirect(url_for('recibo_venda', id_venda=nova_venda_obj.id_venda))
        
        except Exception as e:
            db.session.rollback()
            flash(f'Ocorreu um erro ao registrar a venda: {e}', 'danger')
            return redirect(url_for('nova_venda'))

    produtos = Produto.query.join(Estoque).filter(Estoque.quantidade_produto > 0).order_by(Produto.nome).all()
    return render_template('nova_venda.html', produtos=produtos)

@app.route('/historico')
def historico():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    movimentacoes = MovimentacaoEstoque.query.order_by(MovimentacaoEstoque.data_movimentacao.desc()).all()
    return render_template('historico.html', movimentacoes=movimentacoes)

# --- APIs ---
@app.route('/api/produto/update', methods=['POST'])
def api_produto_update():
    if 'user_id' not in session:
        return jsonify({"error": "Acesso negado"}), 403
    data = request.json
    pid = data.get('id')
    nova_quantidade = data.get('quantidade')
    if pid is None or nova_quantidade is None:
        return jsonify({"error": "Dados inválidos"}), 400
    produto = Produto.query.get(pid)
    if not produto or not produto.estoque:
        return jsonify({"error": "Produto não encontrado"}), 404
    try:
        quantidade_antiga = produto.estoque.quantidade_produto
        produto.estoque.quantidade_produto = int(nova_quantidade)
        diferenca = int(nova_quantidade) - quantidade_antiga
        mov = MovimentacaoEstoque(id_produto=pid, id_usuario=session.get('user_id'), tipo='AJUSTE MANUAL', quantidade=diferenca, observacao=f'Alterado por {session.get("login", "usuário")}')
        db.session.add(mov)
        db.session.commit()
        return jsonify({"success": True, "message": "Estoque atualizado."})
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@app.route('/api/relatorios/vendas/por_mes')
def vendas_por_mes():
    if 'user_id' not in session or session.get('cargo') != 'GERENTE':
        return jsonify({"error": "Acesso negado"}), 403
    ano = request.args.get('ano', datetime.utcnow().year, type=int)
    totais = [0.0] * 12
    vendas_no_ano = db.session.query(Venda).filter(db.extract('year', Venda.data_compra) == ano).all()
    for v in vendas_no_ano:
        if v.data_compra:
            mes = v.data_compra.month - 1
            totais[mes] += float(v.valor_total or 0.0)
    return jsonify({"ano": ano, "mensal": totais})

@app.route('/api/relatorios/estoque_atual')
def estoque_atual():
    if 'user_id' not in session or session.get('cargo') != 'GERENTE':
        return jsonify({"error": "Acesso negado"}), 403
    produtos = Produto.query.join(Estoque).order_by(Estoque.quantidade_produto.desc()).all()
    labels = [p.nome for p in produtos]
    data = [p.estoque.quantidade_produto for p in produtos]
    return jsonify({'labels': labels, 'data': data})

@app.route('/api/cliente/cpf/<string:cpf>')
def api_buscar_cliente_por_cpf(cpf):
    """Busca um cliente pelo CPF (limpo) e retorna em JSON."""
    cpf_limpo = ''.join(filter(str.isdigit, cpf))
    if not valida_cpf(cpf_limpo):
        return jsonify({'error': 'CPF inválido'}), 400
    cliente = Cliente.query.filter_by(cpf=cpf_limpo).first()
    if cliente:
        return jsonify({'id_cliente': cliente.id_cliente, 'nome': cliente.nome, 'cpf': cliente.cpf})
    else:
        return jsonify({'error': 'Cliente não encontrado'}), 404

@app.route('/api/cliente/novo', methods=['POST'])
def api_cadastrar_cliente():
    """Cadastra um novo cliente e retorna em JSON."""
    data = request.json
    nome = data.get('nome')
    cpf = data.get('cpf')
    telefone = data.get('telefone')
    cep = data.get('cep')
    numero = data.get('numero')
    if not nome or not cpf:
        return jsonify({'error': 'Nome e CPF são obrigatórios'}), 400
    cpf_limpo = ''.join(filter(str.isdigit, cpf))
    if not valida_cpf(cpf_limpo):
        return jsonify({'error': 'CPF com formato inválido'}), 400
    if Cliente.query.filter_by(cpf=cpf_limpo).first():
        return jsonify({'error': 'CPF já cadastrado'}), 409
    try:
        novo_endereco = Endereco(cep=cep or 'N/A', numero=numero or 'S/N')
        db.session.add(novo_endereco)
        db.session.flush()
        novo_cliente = Cliente(nome=nome, cpf=cpf_limpo, telefone=telefone, id_endereco=novo_endereco.id_endereco)
        db.session.add(novo_cliente)
        db.session.commit()
        return jsonify({'id_cliente': novo_cliente.id_cliente, 'nome': novo_cliente.nome, 'cpf': novo_cliente.cpf}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Erro ao salvar no banco: {str(e)}'}), 500

# --- ROTAS DE EXPORTAÇÃO DE RELATÓRIOS ---
@app.route('/export/produtos')
def exportar_produtos():
    if 'user_id' not in session or session.get('cargo') != 'GERENTE':
        flash('Acesso negado.', 'danger')
        return redirect(url_for('estoque'))
    try:
        produtos = Produto.query.join(Estoque).all()
        dados_para_exportar = []
        for p in produtos:
            dados_para_exportar.append({
                'ID': p.id_produto, 'Nome': p.nome, 'Descrição': p.descricao,
                'Preço (R$)': float(p.preco), 'Quantidade em Estoque': p.estoque.quantidade_produto,
                'Estoque Mínimo': p.estoque.min_produto, 'Fornecedor': p.fornecedor.nome if p.fornecedor else 'N/A'
            })
        df = pd.DataFrame(dados_para_exportar)
        output = BytesIO()
        writer = pd.ExcelWriter(output, engine='xlsxwriter')
        df.to_excel(writer, index=False, sheet_name='Produtos')
        writer.close()
        output.seek(0)
        return send_file(output, download_name='relatorio_produtos.xlsx', as_attachment=True)
    except Exception as e:
        flash(f"Erro ao gerar relatório: {e}", "danger")
        return redirect(url_for('estoque'))

@app.route('/export/historico')
def exportar_historico():
    if 'user_id' not in session or session.get('cargo') != 'GERENTE':
        flash('Acesso negado.', 'danger')
        return redirect(url_for('historico'))
    try:
        movimentacoes = MovimentacaoEstoque.query.order_by(MovimentacaoEstoque.data_movimentacao.desc()).all()
        dados_para_exportar = []
        for mov in movimentacoes:
            dados_para_exportar.append({
                'Data': mov.data_movimentacao.strftime('%d/%m/%Y %H:%M:%S'), 'Produto': mov.produto.nome,
                'Tipo': mov.tipo, 'Quantidade': mov.quantidade, 'Usuário': mov.usuario.login if mov.usuario else 'Sistema',
                'Observação': mov.observacao
            })
        df = pd.DataFrame(dados_para_exportar)
        output = BytesIO()
        writer = pd.ExcelWriter(output, engine='xlsxwriter')
        df.to_excel(writer, index=False, sheet_name='Historico_Movimentacoes')
        writer.close()
        output.seek(0)
        return send_file(output, download_name='relatorio_historico.xlsx', as_attachment=True)
    except Exception as e:
        flash(f"Erro ao gerar relatório: {e}", "danger")
        return redirect(url_for('historico'))

@app.route('/export/vendas')
def exportar_vendas():
    if 'user_id' not in session or session.get('cargo') != 'GERENTE':
        flash('Acesso negado.', 'danger')
        return redirect(url_for('vendas'))
    try:
        lista_vendas = db.session.query(Venda).options(
            joinedload(Venda.cliente), 
            joinedload(Venda.itens)
        ).order_by(Venda.data_compra.desc()).all()
        dados_para_exportar = []
        for venda in lista_vendas:
            dados_para_exportar.append({
                'ID da Venda': venda.id_venda,
                'Cliente': venda.cliente.nome if venda.cliente else 'N/A',
                'Data': venda.data_compra.strftime('%d/%m/%Y'),
                'Nº de Itens': len(venda.itens),
                'Valor Total (R$)': float(venda.valor_total)
            })
        df = pd.DataFrame(dados_para_exportar)
        output = BytesIO()
        with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
            df.to_excel(writer, index=False, sheet_name='Historico_Vendas')
            workbook  = writer.book
            worksheet = writer.sheets['Historico_Vendas']
            money_format = workbook.add_format({'num_format': 'R$ #,##0.00'})
            worksheet.set_column('A:A', 12)
            worksheet.set_column('B:B', 30)
            worksheet.set_column('C:C', 12)
            worksheet.set_column('D:D', 12)
            worksheet.set_column('E:E', 20, money_format)
        output.seek(0)
        return send_file(
            output, 
            download_name='relatorio_vendas.xlsx', 
            as_attachment=True,
            mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )
    except Exception as e:
        flash(f"Erro ao gerar relatório de vendas: {e}", "danger")
        return redirect(url_for('vendas'))


# =======================================================================
# COMANDO DE SETUP SIMPLIFICADO
# =======================================================================
@app.cli.command("setup")
def setup_command():
    """
    Garante que as tabelas existam e que os usuários essenciais (admin, seller)
    tenham suas senhas corretamente criptografadas.
    """
    print("--- Iniciando Setup da Aplicação ---")
    print("1. Garantindo que todas as tabelas existam...")
    db.create_all()
    print("2. Verificando e atualizando senhas dos usuários essenciais...")
    seed_essentials()
    print("\n--- Setup da Aplicação Concluído! ---")
    print("O banco de dados principal deve ser populado via script SQL.")
    print("Este comando apenas garante as senhas corretas para login.")


# --- Inicialização ---
if __name__ == '__main__':
    app.run(debug=True, port=int(os.getenv('PORT', '5000')))