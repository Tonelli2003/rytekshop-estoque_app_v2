-- ================================
-- SCRIPT DE CRIAÇÃO DO BANCO DE DADOS - RYTEKSHOP
-- Este script reflete a estrutura completa do banco de dados,
-- incluindo todas as funcionalidades implementadas (Pedidos, Vendas, Histórico, etc.).
-- ================================

-- Cria o banco de dados se ele não existir, garantindo suporte a acentos e caracteres especiais.
CREATE DATABASE IF NOT EXISTS rytekshop 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- Seleciona o banco de dados para executar os comandos seguintes.
USE rytekshop;


-- ================================
-- TABELAS DE SUPORTE (ENTIDADES BÁSICAS)
-- ================================

-- Tabela ENDERECO
-- Armazena endereços que podem ser reutilizados por Clientes, Fornecedores, etc.
CREATE TABLE ENDERECO (
    id_endereco INT AUTO_INCREMENT PRIMARY KEY,
    cep VARCHAR(10) NOT NULL,
    numero VARCHAR(8) NOT NULL,
    complemento VARCHAR(100)
);

-- Tabela CONTA (referente ao modelo 'Usuario' no Python)
-- Armazena as contas de login, senhas (criptografadas) e os cargos/permissões.
CREATE TABLE CONTA (
    id_conta INT AUTO_INCREMENT PRIMARY KEY,
    login VARCHAR(80) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    cargo VARCHAR(20) NOT NULL -- Ex: 'GERENTE', 'VENDEDOR'
);

-- Tabela CATEGORIA
-- Organiza os produtos em categorias.
CREATE TABLE CATEGORIA (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nome_categoria VARCHAR(50) NOT NULL
);

-- Tabela PAGAMENTO
-- Armazena as formas de pagamento para o registro de vendas.
CREATE TABLE PAGAMENTO (
    id_pagamento INT AUTO_INCREMENT PRIMARY KEY,
    tipo VARCHAR(20) NOT NULL,
    parcela INT DEFAULT 1
);


-- ================================
-- TABELAS PRINCIPAIS (ENTIDADES DE NEGÓCIO)
-- ================================

-- Tabela FORNECEDOR
-- Armazena os dados dos fornecedores de produtos.
CREATE TABLE FORNECEDOR (
    id_fornecedor INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    email VARCHAR(200),
    cnpj VARCHAR(18) NOT NULL UNIQUE,
    telefone VARCHAR(20),
    id_endereco INT NOT NULL,
    FOREIGN KEY (id_endereco) REFERENCES ENDERECO(id_endereco)
);

-- Tabela CLIENTE
-- Armazena os dados dos clientes que realizam as compras.
CREATE TABLE CLIENTE (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) NOT NULL UNIQUE,
    id_endereco INT NOT NULL,
    FOREIGN KEY (id_endereco) REFERENCES ENDERECO(id_endereco)
);

-- Tabela ESTOQUE
-- Controla a quantidade de cada produto.
CREATE TABLE ESTOQUE (
    id_estoque INT AUTO_INCREMENT PRIMARY KEY,
    quantidade_produto INT DEFAULT 0,
    min_produto INT DEFAULT 1,
    last_alert DATETIME NULL -- Guarda a data do último alerta de estoque baixo (funcionalidade futura).
);

-- Tabela PRODUTO
-- Tabela central que armazena as informações de cada item vendido.
CREATE TABLE PRODUTO (
    id_produto INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    descricao TEXT,
    preco DECIMAL(10,2) DEFAULT 0.00,
    preco_promocional DECIMAL(10,2) NULL, -- Coluna para o sistema de promoções.
    id_categoria INT NOT NULL,
    fornecedor_id INT,
    estoque_id INT NOT NULL,
    FOREIGN KEY (id_categoria) REFERENCES CATEGORIA(id_categoria),
    FOREIGN KEY (fornecedor_id) REFERENCES FORNECEDOR(id_fornecedor),
    FOREIGN KEY (estoque_id) REFERENCES ESTOQUE(id_estoque)
);


-- ================================
-- TABELAS DE TRANSAÇÕES E LOGS
-- ================================

-- Tabela VENDA
-- Registra a "capa" de cada transação de venda.
CREATE TABLE VENDA (
    id_venda INT AUTO_INCREMENT PRIMARY KEY,
    data_compra DATE NOT NULL,
    valor_total DECIMAL(12,2) DEFAULT 0.00,
    id_cliente INT NOT NULL,
    id_pagamento INT NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente),
    FOREIGN KEY (id_pagamento) REFERENCES PAGAMENTO(id_pagamento)
);

-- Tabela PRODUTO_VENDA (Tabela de Junção)
-- Detalha quais produtos e quantidades foram vendidos em cada venda.
CREATE TABLE PRODUTO_VENDA (
    id_produto INT NOT NULL,
    id_venda INT NOT NULL,
    quantidade INT DEFAULT 1,
    preco_unitario DECIMAL(10,2) NOT NULL, -- Guarda o preço no momento da venda (seja normal ou promocional).
    PRIMARY KEY (id_produto, id_venda),
    FOREIGN KEY (id_produto) REFERENCES PRODUTO(id_produto),
    FOREIGN KEY (id_venda) REFERENCES VENDA(id_venda) ON DELETE CASCADE
);

-- Tabela PEDIDO_FORNECEDOR
-- Registra a "capa" de cada pedido de compra feito a um fornecedor.
CREATE TABLE PEDIDO_FORNECEDOR (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_fornecedor INT NOT NULL,
    data_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'Pendente', -- Ex: 'Pendente', 'Recebido'
    FOREIGN KEY (id_fornecedor) REFERENCES FORNECEDOR(id_fornecedor)
);

-- Tabela PEDIDO_PRODUTO (Tabela de Junção)
-- Detalha quais produtos e quantidades foram solicitados em cada pedido.
CREATE TABLE PEDIDO_PRODUTO (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade_pedida INT NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES PEDIDO_FORNECEDOR(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (id_produto) REFERENCES PRODUTO(id_produto)
);

-- Tabela MENSAGEM
-- Armazena um log de mensagens enviadas (manualmente ou automaticamente pelo sistema).
CREATE TABLE MENSAGEM (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fornecedor_id INT,
    produto_id INT,
    conteudo VARCHAR(2000),
    data_envio DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'pendente',
    FOREIGN KEY (fornecedor_id) REFERENCES FORNECEDOR(id_fornecedor),
    FOREIGN KEY (produto_id) REFERENCES PRODUTO(id_produto)
);

-- Tabela MOVIMENTACAO_ESTOQUE
-- Tabela de auditoria para todas as alterações de estoque. A mais importante para relatórios.
CREATE TABLE MOVIMENTACAO_ESTOQUE (
    id_mov INT AUTO_INCREMENT PRIMARY KEY,
    id_produto INT NOT NULL,
    id_usuario INT, -- ID do usuário que realizou a ação.
    tipo VARCHAR(50) NOT NULL, -- 'ENTRADA', 'SAÍDA', 'AJUSTE MANUAL'
    quantidade INT NOT NULL,
    data_movimentacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    observacao VARCHAR(255), -- Ex: 'Venda #101', 'Recebimento do Pedido #15'
    FOREIGN KEY (id_produto) REFERENCES PRODUTO(id_produto),
    FOREIGN KEY (id_usuario) REFERENCES CONTA(id_conta)
);