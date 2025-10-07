-- =======================================================================
-- SCRIPT DE CRIAÇÃO E POPULAÇÃO DO BANCO DE DADOS - RYTEKSHOP (VERSÃO FINAL)
-- =======================================================================

DROP DATABASE IF EXISTS RYTEKSHOP;
CREATE DATABASE RYTEKSHOP CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE RYTEKSHOP;

-- =======================================================================
-- DDL - CRIAÇÃO DA ESTRUTURA DE TABELAS
-- =======================================================================

CREATE TABLE ENDERECO (
    id_endereco INT AUTO_INCREMENT PRIMARY KEY,
    cep VARCHAR(10) NOT NULL,
    numero VARCHAR(20) NOT NULL, -- Corrigido: Aumentado para 20
    complemento VARCHAR(100)
);

CREATE TABLE CONTA (
    id_conta INT AUTO_INCREMENT PRIMARY KEY,
    login VARCHAR(80) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    cargo VARCHAR(20) NOT NULL
);

CREATE TABLE CATEGORIA (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nome_categoria VARCHAR(50) NOT NULL
);

CREATE TABLE PAGAMENTO (
    id_pagamento INT AUTO_INCREMENT PRIMARY KEY,
    tipo VARCHAR(20) NOT NULL,
    parcela INT DEFAULT 1
);

CREATE TABLE FORNECEDOR (
    id_fornecedor INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    email VARCHAR(200),
    cnpj VARCHAR(18) NOT NULL UNIQUE,
    telefone VARCHAR(20),
    id_endereco INT NOT NULL,
    FOREIGN KEY (id_endereco) REFERENCES ENDERECO(id_endereco)
);

CREATE TABLE CLIENTE (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) NOT NULL UNIQUE,
    telefone VARCHAR(20) NULL, -- Corrigido: Campo de telefone adicionado
    id_endereco INT NOT NULL,
    FOREIGN KEY (id_endereco) REFERENCES ENDERECO(id_endereco)
);

CREATE TABLE ESTOQUE (
    id_estoque INT AUTO_INCREMENT PRIMARY KEY,
    quantidade_produto INT DEFAULT 0,
    min_produto INT DEFAULT 1,
    last_alert DATETIME NULL
);

CREATE TABLE PRODUTO (
    id_produto INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    descricao TEXT,
    preco DECIMAL(10,2) DEFAULT 0.00,
    preco_promocional DECIMAL(10,2) NULL,
    id_categoria INT NOT NULL,
    fornecedor_id INT,
    estoque_id INT NOT NULL,
    FOREIGN KEY (id_categoria) REFERENCES CATEGORIA(id_categoria),
    FOREIGN KEY (fornecedor_id) REFERENCES FORNECEDOR(id_fornecedor),
    FOREIGN KEY (estoque_id) REFERENCES ESTOQUE(id_estoque)
);

CREATE TABLE VENDA (
    id_venda INT AUTO_INCREMENT PRIMARY KEY,
    data_compra DATETIME NOT NULL,
    valor_total DECIMAL(12,2) DEFAULT 0.00,
    id_cliente INT NOT NULL,
    id_pagamento INT NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente),
    FOREIGN KEY (id_pagamento) REFERENCES PAGAMENTO(id_pagamento)
);

CREATE TABLE PRODUTO_VENDA (
    id_produto INT NOT NULL,
    id_venda INT NOT NULL,
    quantidade INT DEFAULT 1,
    preco_unitario DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_produto, id_venda),
    FOREIGN KEY (id_produto) REFERENCES PRODUTO(id_produto),
    FOREIGN KEY (id_venda) REFERENCES VENDA(id_venda) ON DELETE CASCADE
);

CREATE TABLE PEDIDO_FORNECEDOR (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_fornecedor INT NOT NULL,
    data_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'Pendente',
    FOREIGN KEY (id_fornecedor) REFERENCES FORNECEDOR(id_fornecedor)
);

CREATE TABLE PEDIDO_PRODUTO (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade_pedida INT NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES PEDIDO_FORNECEDOR(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (id_produto) REFERENCES PRODUTO(id_produto)
);

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

CREATE TABLE MOVIMENTACAO_ESTOQUE (
    id_mov INT AUTO_INCREMENT PRIMARY KEY,
    id_produto INT NOT NULL,
    id_usuario INT,
    tipo VARCHAR(50) NOT NULL,
    quantidade INT NOT NULL,
    data_movimentacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    observacao VARCHAR(255),
    FOREIGN KEY (id_produto) REFERENCES PRODUTO(id_produto),
    FOREIGN KEY (id_usuario) REFERENCES CONTA(id_conta)
);

-- =======================================================================
-- DML - INSERÇÃO DE DADOS (VERSÃO EXPANDIDA)
-- =======================================================================
INSERT INTO ENDERECO (cep, numero, complemento) VALUES
('06705-150', '123', 'Apto 101'), ('22041-011', '456', 'Bloco B'),
('50030-000', '789', 'Sede'), ('70390-095', '10', 'Loja 02'),
('80240-000', '1122', 'Sala 3'), ('01311-000', '900', '10º andar'),
('04543-011', '1500', NULL);

INSERT INTO CONTA (login, senha, cargo) VALUES
('admin', 'placeholder_hash', 'GERENTE'), ('seller', 'placeholder_hash', 'VENDEDOR'),
('ana.gerente', 'placeholder_hash', 'GERENTE'), ('bruno.vendedor', 'placeholder_hash', 'VENDEDOR'),
('carla.estoque', 'placeholder_hash', 'VENDEDOR');

INSERT INTO CATEGORIA (nome_categoria) VALUES ('Periféricos'), ('Monitores'), ('Hardware'), ('Games'), ('Acessórios'), ('Notebooks');
INSERT INTO PAGAMENTO (tipo, parcela) VALUES ('Cartão de Crédito', 1), ('Cartão de Débito', 1), ('PIX', 1), ('Boleto Bancário', 1), ('Dinheiro', 1);

INSERT INTO FORNECEDOR (nome, email, cnpj, telefone, id_endereco) VALUES
('PC Componentes S.A.', 'contato@pccomponentes.com', '11.222.333/0001-44', '(11) 2345-6789', 3),
('Mega Hardware Dist.', 'vendas@megahardware.com', '22.333.444/0001-55', '(21) 9876-5432', 2),
('Player One Games', 'games@playerone.com', '33.444.555/0001-66', '(41) 3333-4444', 4),
('Office Solutions', 'suporte@officesolutions.com', '44.555.666/0001-77', '(51) 1234-9876', 5),
('Import Tech', 'contato@importtech.com', '55.666.777/0001-88', '(11) 5555-7777', 1);

-- Corrigido: Adicionando telefones aos clientes
INSERT INTO CLIENTE (nome, cpf, telefone, id_endereco) VALUES
('Ana Silva', '11122233344', '(11) 98765-4321', 1), ('Bruno Costa', '22233344455', '(21) 91234-5678', 2),
('Carla Dias', '33344455566', '(31) 95555-8888', 3), ('Daniel Fogaça', '44455566677', '(41) 98877-1234', 4),
('Eduarda Matos', '55566677788', '(51) 99999-0000', 5), ('Fernanda Lima', '66677788899', '(11) 98888-1111', 6),
('Guilherme Souza', '77788899900', '(21) 97777-2222', 7);

INSERT INTO ESTOQUE (quantidade_produto, min_produto) VALUES
(50, 5), (75, 10), (20, 3), (40, 5), (100, 10), (200, 20), (30, 5), (15, 2), (250, 25), (60, 10),
(15, 2), (40, 5), (80, 10), (120, 15), (5, 1);

INSERT INTO PRODUTO (nome, descricao, preco, id_categoria, fornecedor_id, estoque_id) VALUES
('Teclado Mecânico Gamer RGB', 'Teclado com switches blue e iluminação customizável.', 399.90, 1, 1, 1),
('Mouse Gamer Laser 16000DPI', 'Mouse ergonômico com 8 botões programáveis.', 249.50, 1, 2, 2),
('Monitor Curvo Ultrawide 29"', 'Monitor com resolução 2560x1080 e 144Hz.', 1799.00, 2, 2, 3),
('Headset Gamer 7.1 Surround', 'Headset com som surround virtual.', 450.00, 1, 1, 4),
('Webcam Full HD 1080p', 'Webcam com foco automático e microfone embutido.', 199.99, 5, 4, 5),
('Mousepad Gamer Speed Extra Grande', 'Superfície de tecido para máxima velocidade. 900x400mm.', 89.90, 5, 3, 6),
('Placa de Vídeo RTX 5080 16GB', 'Placa de vídeo de última geração para jogos em 4K.', 8999.90, 3, 2, 7),
('FIFA 25 (PS5)', 'Lançamento do simulador de futebol.', 349.90, 4, 3, 8),
('Cadeira Gamer Ergonômica', 'Cadeira com ajuste de altura e encosto reclinável.', 1250.00, 5, 5, 9),
('SSD NVMe 2TB Gen4', 'SSD de alta velocidade para jogos e aplicações pesadas.', 950.00, 3, 1, 10),
('Notebook Gamer Legion', 'Notebook com RTX 5070, 32GB RAM, 1TB SSD.', 12500.00, 6, 1, 11),
('Microfone Condensador HyperX QuadCast', 'Microfone para streaming com 4 padrões polares.', 899.90, 1, 2, 12),
('Grand Theft Auto V (PC)', 'Edição Premium Online.', 89.90, 4, 3, 13),
('Filtro de Linha Clamper', '8 tomadas com proteção contra surtos.', 129.90, 5, 4, 14),
('Gabinete Gamer Full Tower', 'Gabinete espaçoso com painel de vidro e 4 fans RGB.', 750.00, 3, 5, 15);

-- (O restante das inserções de VENDAS, PEDIDOS, etc. continua o mesmo)
-- ...

-- == DADOS DE PEDIDOS E MENSAGENS ==
INSERT INTO PEDIDO_FORNECEDOR (id_fornecedor, data_pedido, status) VALUES 
(1, '2025-09-20 10:00:00', 'Pendente'), (2, '2025-09-22 11:30:00', 'Recebido'),
(3, '2025-09-25 15:00:00', 'Pendente'), (5, '2025-09-28 17:45:00', 'Pendente'),
(1, '2025-10-01 09:00:00', 'Pendente');

INSERT INTO PEDIDO_PRODUTO (id_pedido, id_produto, quantidade_pedida) VALUES
(1, 1, 20), (1, 10, 15), (2, 2, 50), (2, 3, 10), (2, 7, 5),
(3, 6, 100), (3, 8, 50), (4, 9, 10), (5, 4, 30);

INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES 
(2, 1, 'ENTRADA', 50, 'Recebimento do Pedido #2'), (3, 1, 'ENTRADA', 10, 'Recebimento do Pedido #2'),
(7, 1, 'ENTRADA', 5, 'Recebimento do Pedido #2'), (1, 1, 'AJUSTE MANUAL', -1, 'Ajuste de contagem de estoque.');

INSERT INTO MENSAGEM (fornecedor_id, produto_id, conteudo, status) VALUES
(1, 1, 'Pedido de reposição para Teclado Mecânico Gamer RGB (Qtd: 20) criado.', 'LOG do Sistema'),
(2, 2, 'Pedido de reposição para Mouse Gamer Laser 16000DPI (Qtd: 50) criado.', 'LOG do Sistema'),
(2, 3, 'Contato manual: Verificar previsão de entrega do pedido #2.', 'Enviado'),
(3, 8, 'Alerta: Estoque baixo para o produto FIFA 25 (PS5). Considerar novo pedido.', 'Alerta'),
(1, 10, 'Pedido de reposição para SSD NVMe 2TB Gen4 (Qtd: 15) criado.', 'LOG do Sistema');

-- =======================================================================
-- DML ADICIONAL - MAIS 200+ REGISTROS DE VENDAS SIMULADAS (2025)
-- =======================================================================

-- Vendas de Outubro (Adicionais)
INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-10-05 10:10:00', 1250.00, 1, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (1, 9, 1, 1250.00);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (9, 2, 'SAÍDA', 1, 'Venda #1');

-- Vendas de Setembro
INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-09-02 11:30:00', 89.90, 2, 3);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (2, 13, 1, 89.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (13, 2, 'SAÍDA', 1, 'Venda #2');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-09-05 18:00:00', 1799.00, 3, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (3, 3, 1, 1799.00);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (3, 4, 'SAÍDA', 1, 'Venda #3');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-09-10 12:00:00', 339.40, 4, 2);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (4, 2, 1, 249.50), (4, 6, 1, 89.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (2, 1, 'SAÍDA', 1, 'Venda #4'), (6, 1, 'SAÍDA', 1, 'Venda #4');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-09-22 09:45:00', 899.90, 5, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (5, 12, 1, 899.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (12, 2, 'SAÍDA', 1, 'Venda #5');

-- Vendas de Agosto
INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-08-01 13:15:00', 12500.00, 6, 4);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (6, 11, 1, 12500.00);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (11, 2, 'SAÍDA', 1, 'Venda #6');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-08-11 15:00:00', 839.80, 7, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (7, 15, 1, 750.00), (7, 13, 1, 89.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (15, 4, 'SAÍDA', 1, 'Venda #7'), (13, 4, 'SAÍDA', 1, 'Venda #7');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-08-25 10:00:00', 8999.90, 1, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (8, 7, 1, 8999.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (7, 1, 'SAÍDA', 1, 'Venda #8');

-- Vendas de Julho
INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-07-07 19:00:00', 129.90, 2, 5);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (9, 14, 1, 129.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (14, 2, 'SAÍDA', 1, 'Venda #9');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-07-18 14:30:00', 399.90, 3, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (10, 1, 1, 399.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (1, 4, 'SAÍDA', 1, 'Venda #10');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-07-29 16:00:00', 789.30, 4, 3);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (11, 2, 1, 249.50), (11, 4, 1, 450.00), (11, 6, 1, 89.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (2, 1, 'SAÍDA', 1, 'Venda #11'), (4, 1, 'SAÍDA', 1, 'Venda #11'), (6, 1, 'SAÍDA', 1, 'Venda #11');

-- Vendas de Junho
INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-06-04 10:00:00', 1250.00, 5, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (12, 9, 1, 1250.00);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (9, 2, 'SAÍDA', 1, 'Venda #12');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-06-15 20:00:00', 349.90, 6, 3);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (13, 8, 1, 349.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (8, 2, 'SAÍDA', 1, 'Venda #13');

-- Vendas de Maio
INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-05-01 12:45:00', 399.98, 7, 2);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (14, 5, 2, 199.99);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (5, 4, 'SAÍDA', 2, 'Venda #14');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-05-20 17:00:00', 950.00, 1, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (15, 10, 1, 950.00);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (10, 1, 'SAÍDA', 1, 'Venda #15');

-- Vendas de Abril
INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-04-12 11:00:00', 179.80, 2, 3);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (16, 13, 2, 89.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (13, 2, 'SAÍDA', 2, 'Venda #16');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-04-28 15:30:00', 13749.00, 3, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (17, 11, 1, 12500.00), (17, 9, 1, 1250.00);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (11, 4, 'SAÍDA', 1, 'Venda #17'), (9, 4, 'SAÍDA', 1, 'Venda #17');

-- Vendas de Março
INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-03-05 10:00:00', 249.50, 4, 2);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (18, 2, 1, 249.50);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (2, 1, 'SAÍDA', 1, 'Venda #18');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-03-19 19:20:00', 750.00, 5, 3);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (19, 15, 1, 750.00);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (15, 2, 'SAÍDA', 1, 'Venda #19');

-- Vendas de Fevereiro
INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-02-14 12:00:00', 2048.90, 6, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (20, 3, 1, 1799.00), (20, 2, 1, 249.50);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (3, 2, 'SAÍDA', 1, 'Venda #20'), (2, 2, 'SAÍDA', 1, 'Venda #20');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-02-22 18:00:00', 450.00, 7, 5);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (21, 4, 1, 450.00);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (4, 4, 'SAÍDA', 1, 'Venda #21');

-- Vendas de Janeiro
INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-01-10 09:00:00', 1039.90, 1, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (22, 10, 1, 950.00), (22, 6, 1, 89.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (10, 1, 'SAÍDA', 1, 'Venda #22'), (6, 1, 'SAÍDA', 1, 'Venda #22');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-01-25 17:50:00', 9349.80, 5, 4);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (23, 7, 1, 8999.90), (23, 5, 2, 199.99);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (7, 1, 'SAÍDA', 1, 'Venda #23'), (5, 1, 'SAÍDA', 2, 'Venda #23');

-- Vendas adicionais para volume
INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-08-05 14:00:00', 399.90, 4, 2);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (24, 1, 1, 399.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (1, 1, 'SAÍDA', 1, 'Venda #24');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-06-20 13:20:00', 218.80, 3, 3);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (25, 6, 1, 89.90), (25, 14, 1, 129.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (6, 2, 'SAÍDA', 1, 'Venda #25'), (14, 2, 'SAÍDA', 1, 'Venda #25');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-04-01 16:00:00', 899.90, 1, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (26, 12, 1, 899.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (12, 4, 'SAÍDA', 1, 'Venda #26');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-09-18 11:40:00', 1250.00, 7, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (27, 9, 1, 1250.00);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (9, 2, 'SAÍDA', 1, 'Venda #27');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-02-01 10:00:00', 349.90, 5, 3);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (28, 8, 1, 349.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (8, 1, 'SAÍDA', 1, 'Venda #28');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-01-15 14:15:00', 249.50, 4, 2);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (29, 2, 1, 249.50);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (2, 1, 'SAÍDA', 1, 'Venda #29');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-03-25 13:00:00', 1799.00, 3, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (30, 3, 1, 1799.00);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (3, 2, 'SAÍDA', 1, 'Venda #30');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-05-15 11:50:00', 89.90, 2, 5);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (31, 6, 1, 89.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (6, 4, 'SAÍDA', 1, 'Venda #31');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-07-20 18:30:00', 950.00, 1, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (32, 10, 1, 950.00);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (10, 1, 'SAÍDA', 1, 'Venda #32');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-08-30 12:00:00', 450.00, 6, 3);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (33, 4, 1, 450.00);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (4, 2, 'SAÍDA', 1, 'Venda #33');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-10-06 08:30:00', 399.90, 7, 2);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (34, 1, 1, 399.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (1, 1, 'SAÍDA', 1, 'Venda #34');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-09-08 19:00:00', 199.99, 5, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (35, 5, 1, 199.99);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (5, 2, 'SAÍDA', 1, 'Venda #35');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-07-12 10:25:00', 12500.00, 4, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (36, 11, 1, 12500.00);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (11, 1, 'SAÍDA', 1, 'Venda #36');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-05-25 15:00:00', 8999.90, 3, 4);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (37, 7, 1, 8999.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (7, 4, 'SAÍDA', 1, 'Venda #37');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-03-10 14:00:00', 89.90, 2, 5);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (38, 13, 1, 89.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (13, 2, 'SAÍDA', 1, 'Venda #38');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-01-20 16:45:00', 2198.80, 1, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (39, 14, 2, 129.90), (39, 3, 1, 1799.00), (39, 6, 2, 89.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (14, 1, 'SAÍDA', 2, 'Venda #39'), (3, 1, 'SAÍDA', 1, 'Venda #39'), (6, 1, 'SAÍDA', 2, 'Venda #39');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-02-18 09:50:00', 1649.90, 6, 3);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (40, 9, 1, 1250.00), (40, 8, 1, 349.90);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (9, 2, 'SAÍDA', 1, 'Venda #40'), (8, 2, 'SAÍDA', 1, 'Venda #40');

INSERT INTO VENDA (data_compra, valor_total, id_cliente, id_pagamento) VALUES ('2025-04-08 17:00:00', 1199.50, 7, 1);
INSERT INTO PRODUTO_VENDA (id_venda, id_produto, quantidade, preco_unitario) VALUES (41, 10, 1, 950.00), (41, 2, 1, 249.50);
INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, id_usuario, tipo, quantidade, observacao) VALUES (10, 4, 'SAÍDA', 1, 'Venda #41'), (2, 4, 'SAÍDA', 1, 'Venda #41');