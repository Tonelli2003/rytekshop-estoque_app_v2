# RytekShop - Sistema de Gestão de Estoque

**Grupo:**
* AUGUSTO OLIVEIRA CODO DE SOUSA – 562080
* FELIPE DE OLIVEIRA CABRAL – 561720
* GABRIEL TONELLI AVELINO DOS SANTOS – 564705
* SOFIA BUERIS NETTO DE SOUZA – 565818
* VINÍCIUS ADRIAN SIQUEIRA DE OLIVEIRA – 564962

---

RytekShop é um sistema web completo para gestão de estoque, construído com Python e Flask. Ele oferece um fluxo de trabalho completo, desde o cadastro de produtos, passando pela compra de mercadorias, até o registro de vendas e a análise de dados através de um dashboard inteligente.

## ✨ Funcionalidades Principais

#### Gestão de Acesso e Usuários
- **Níveis de Permissão:** Dois tipos de conta com acessos distintos:
  - **Gerente:** Acesso total a todas as funcionalidades do sistema.
  - **Vendedor:** Acesso focado na operação diária (vendas, consulta de estoque e pedidos).
- **Cadastro de Contas:** Página pública para o registro de novas contas de Vendedor.

#### Dashboard Inteligente (Acesso de Gerente)
- **Gráficos Visuais:** Gráfico de barras para vendas mensais (com seletor de ano) e gráfico de rosca para a distribuição do valor do estoque.
- **KPIs Ativos:**
  - **Alerta de Estoque Baixo:** Lista automática de produtos que atingiram o nível mínimo de estoque e precisam de reposição.
  - **Produtos Parados:** Identifica itens que não são vendidos há mais de 90 dias, sugerindo a criação de promoções para movimentar o estoque.
- **Promoções Inteligentes:** Crie promoções com preço sugerido diretamente a partir do painel de produtos parados.

#### Gestão de Produtos e Estoque
- **CRUD de Produtos:** Funções completas para Adicionar, Visualizar e Atualizar produtos.
- **Busca Rápida:** Filtre e encontre produtos facilmente pelo nome.
- **Edição Rápida de Estoque:** Altere a quantidade de um produto com um duplo clique na página de estoque, sem precisar recarregar a página.
- **Alertas Visuais:** Produtos com estoque baixo são destacados visualmente para fácil identificação.

#### Fluxo de Compras (Pedidos a Fornecedores)
- **Criação de Pedidos:** Crie pedidos de compra completos com múltiplos itens.
- **Recebimento de Mercadorias:** Confirme a chegada de um pedido, ajuste as quantidades recebidas e atualize o estoque de todos os itens com um único clique.
- **Log Automático:** Cada novo pedido gera um registro automático na página de "Mensagens".

#### Fluxo de Vendas
- **Registro de Vendas:** Uma página dedicada para registrar vendas, selecionando produtos e quantidades.
- **Baixa Automática de Estoque:** Ao finalizar uma venda, o sistema automaticamente subtrai os itens vendidos do estoque.
- **Emissão de Recibo:** Gere um recibo simples e imprimível para cada venda realizada, acessível tanto após a venda quanto no histórico.
- **Preços Dinâmicos:** O sistema aplica automaticamente os preços promocionais, se existirem.

#### Relatórios e Auditoria
- **Histórico de Vendas:** Liste todas as vendas, acesse os detalhes de cada transação e gere recibos a qualquer momento.
- **Histórico de Movimentações:** Um log completo de todas as entradas, saídas e ajustes manuais de estoque, registrando qual usuário realizou a ação.
- **Exportação para Excel:** Exporte relatórios completos de Produtos, Vendas e do Histórico de Movimentações para análise offline.

## 🚀 Tecnologias Utilizadas
- **Backend:** Python, Flask, SQLAlchemy
- **Banco de Dados:** MySQL
- **Frontend:** HTML, Bootstrap 5, Chart.js, CSS customizado
- **Bibliotecas Python:** Pandas, XlsxWriter, python-dotenv, e outras listadas no `requirements.txt`.

## 🔧 Configuração e Instalação
Siga os passos abaixo para rodar o projeto localmente.

#### 1. Pré-requisitos
- Python 3.8 ou superior
- Servidor MySQL instalado e rodando.

#### 2. Preparar o Ambiente
Clone o repositório e configure o ambiente virtual.

```bash
# 1. Clone o repositório para o seu computador
git clone [https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git](https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git)
cd SEU_REPOSITORIO

# 2. Crie e ative o ambiente virtual
python -m venv venv
.\venv\Scripts\Activate  # No Windows

# 3. Instale todas as dependências
pip install -r requirements.txt
3. Configurar o Banco de Dados
O projeto inclui um script SQL completo que cria a estrutura e popula o banco com dados de simulação.

Abra seu cliente MySQL (Workbench, etc.).

Execute o arquivo script_rytekshop.sql na íntegra. Este comando irá criar o banco de dados RYTEKSHOP, todas as tabelas, e inserir mais de 200 registros para uma simulação robusta.

4. Configurar Variáveis de Ambiente
Na raiz do projeto, crie um arquivo chamado .env.

Cole o conteúdo abaixo e substitua sua_senha_aqui pela sua senha do MySQL.

Ini, TOML

SECRET_KEY='uma-chave-secreta-bem-longa-e-aleatoria-123'
DATABASE_URL='mysql+mysqlconnector://root:sua_senha_aqui@localhost/rytekshop'
5. Corrigir as Senhas dos Usuários
O script SQL insere usuários com senhas de exemplo. Para poder fazer login, execute o comando setup do Flask.

Bash

# Defina a aplicação Flask (só precisa fazer uma vez por terminal no CMD)
set FLASK_APP=app.py

# Rode o setup para criptografar as senhas dos usuários 'admin' e 'seller'
flask setup
Este comando irá encontrar os usuários no banco e atualizar suas senhas para 'admin' e 'seller', respectivamente.

6. Iniciar o Servidor
Agora é só ligar a aplicação:

Bash

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