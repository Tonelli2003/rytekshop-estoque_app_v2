RytekShop - Sistema de Gestão de Inventário
Grupo 
AUGUSTO OLIVEIRA CODO DE SOUSA – 562080
FELIPE DE OLIVEIRA CABRAL – 561720
GABRIEL TONELLI AVELINO DOS SANTOS – 564705
SOFIA BUERIS NETTO DE SOUZA – 565818
VINÍCIUS ADRIAN SIQUEIRA DE OLIVEIRA – 564962


RytekShop é um sistema web completo para gestão de estoque, construído com Python e Flask. Ele oferece um fluxo de trabalho completo, desde o cadastro de produtos, passando pela compra de mercadorias, até o registro de vendas e a análise de dados através de um dashboard inteligente.

✨ Funcionalidades Principais
Gestão de Acesso e Usuários
Níveis de Permissão: Dois tipos de conta com acessos distintos:

Gerente: Acesso total a todas as funcionalidades do sistema.

Vendedor: Acesso focado na operação diária (vendas, gestão de estoque e pedidos).

Cadastro de Contas: Página pública para o registro de novas contas de Vendedor.

Dashboard Inteligente (Acesso de Gerente)
Gráficos Visuais: Gráfico de barras para vendas mensais (com seletor de ano) e gráfico de rosca para a situação atual do estoque.

KPIs Ativos:

Alerta de Estoque Baixo: Lista automática de produtos que precisam de reposição.

Produtos Parados: Identifica itens que não são vendidos há mais de 90 dias, sugerindo a criação de promoções.

Promoções Inteligentes: Crie promoções diretamente a partir do painel de produtos parados, com sugestão de preço.

Gestão de Produtos e Estoque
CRUD de Produtos: Funções completas para Adicionar, Visualizar, Atualizar e Deletar produtos (acesso de Gerente e Vendedor para editar).

Busca Rápida: Filtre e encontre produtos facilmente pelo nome.

Edição Rápida de Estoque: Altere a quantidade de um produto com um duplo clique, sem precisar recarregar a página.

Alertas Visuais: Produtos com estoque baixo ou crítico são destacados visualmente com cores e bordas para fácil identificação.

Fluxo de Compras (Pedidos a Fornecedores)
Criação de Pedidos: Crie pedidos de compra completos com múltiplos itens ou crie um pedido de reposição rápido diretamente do alerta de estoque baixo.

Recebimento de Mercadorias: Confirme a chegada de um pedido, ajuste as quantidades recebidas e atualize o estoque de todos os itens com um único clique.

Log Automático: Cada novo pedido gera um registro automático na página de "Mensagens".

Fluxo de Vendas
Registro de Vendas: Uma página dedicada para registrar vendas, selecionando produtos e quantidades.

Baixa Automática de Estoque: Ao finalizar uma venda, o sistema automaticamente subtrai os itens vendidos do estoque.

Emissão de Recibo: Gere um recibo simples e imprimível para cada venda realizada.

Preços Dinâmicos: O sistema aplica automaticamente os preços promocionais, se existirem.

Relatórios e Auditoria
Histórico de Vendas: Liste todas as vendas e veja os detalhes de cada transação (produtos, quantidades, preços).

Histórico de Movimentações: Um log completo de todas as entradas, saídas e ajustes manuais de estoque, registrando qual usuário realizou a ação.

Exportação para Excel: Exporte relatórios completos de Produtos e do Histórico de Movimentações para análise offline.

🚀 Tecnologias Utilizadas
Backend: Python, Flask, SQLAlchemy

Banco de Dados: MySQL

Frontend: HTML, Bootstrap 5, Chart.js, CSS customizado

Bibliotecas Python: Pandas (para exportação), XlsxWriter, e outras listadas no requirements.txt.

🔧 Configuração e Instalação
Siga os passos abaixo para rodar o projeto localmente.

1. Pré-requisitos

Python 3.8 ou superior

Servidor MySQL instalado e rodando.

2. Preparar o Ambiente

No terminal, na pasta do projeto:

# 1. Crie e ative o ambiente virtual
python -m venv venv
.\venv\Scripts\Activate

# 2. Instale todas as dependências
pip install -r requirements.txt

3. Configurar o Banco de Dados

No seu cliente MySQL (Workbench, etc.), crie um banco de dados vazio:

CREATE DATABASE rytekshop CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

4. Configurar Variáveis de Ambiente

Na raiz do projeto, crie um arquivo chamado .env.

Cole o conteúdo abaixo e substitua pela sua senha do MySQL.

SECRET_KEY=uma-chave-secreta-qualquer
DATABASE_URL=mysql+mysqlconnector://root:sua_senha_aqui@localhost/rytekshop

5. Executar o Setup Completo

No terminal (com o venv ativado), execute o comando único que prepara todo o sistema:

# Defina a aplicação Flask (no CMD do Windows)
set FLASK_APP=app.py

# Rode o setup (pode demorar alguns segundos)
flask setup

Este comando irá criar todas as tabelas, inserir os usuários padrão, importar os produtos do estoque.json e simular as vendas para os gráficos.

6. Iniciar o Servidor

Agora é só ligar a aplicação:

flask run

O sistema estará acessível em http://127.0.0.1:5000.

ใช้งาน Como Usar
Acesse http://127.0.0.1:5000 no seu navegador.

Login de Gerente:

Usuário: admin

Senha: admin

Login de Vendedor:

Usuário: seller

Senha: seller