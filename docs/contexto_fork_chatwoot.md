# 📋 Contexto: Fork do Chatwoot + Kanban próprio

> **Documento gerado em:** 2026-05-29  
> **Projeto analisado:** `e:\Nova pasta\chatwoot-modificado2`  
> **Objetivo do usuário:** Criar um fork próprio do Chatwoot OSS com um Kanban construído do zero, com licença própria.

---

## 1. Análise do projeto `chatwoot-modificado2`

Este projeto é um fork privado do Chatwoot mantido pela **fazer.ai** (`fazer-ai/chatwoot`). Ele possui uma engine privada chamada `fazer_ai/` que adiciona features proprietárias ao Chatwoot OSS, sendo o **Kanban** a principal delas.

### Estrutura do repositório

```
chatwoot-modificado2/
├── app/              → Chatwoot OSS core
├── enterprise/       → Chatwoot Enterprise (OSS também)
├── fazer_ai/         → Engine PRIVADA da fazer.ai (contém o Kanban)
├── config/
│   ├── application.rb  → carrega a engine fazer_ai/ dinamicamente
│   └── routes.rb       → registra as rotas /kanban
└── db/schema.rb        → tabelas kanban_* + coluna kanban_task_id em conversations
```

### Remotes Git do projeto

| Remote | Repositório |
|--------|------------|
| `origin` | `fazer-ai/chatwoot` (fork OSS) |
| `chatwoot-pro` | `fazer-ai/chatwoot-pro` (fork Enterprise/Pro, para releases) |
| `upstream` | `chatwoot/chatwoot` (Chatwoot oficial) |

---

## 2. Onde o Kanban está instalado (fazer_ai engine)

O Kanban é **100% proprietário da fazer.ai**, localizado em `fazer_ai/`:

### Backend Ruby on Rails

| Camada | Localização |
|--------|------------|
| Models (12) | `fazer_ai/app/models/fazer_ai/kanban/` |
| Controllers (11) | `fazer_ai/app/controllers/api/v1/accounts/kanban/` |
| Services | `fazer_ai/app/services/fazer_ai/kanban/` |
| Jobs | `fazer_ai/app/jobs/fazer_ai/kanban/` |
| Listeners | `fazer_ai/app/listeners/fazer_ai/` |
| Policies (Pundit) | `fazer_ai/app/policies/fazer_ai/kanban/` |

**Models principais:**
- `FazerAi::Kanban::Board` — Boards (pipelines)
- `FazerAi::Kanban::BoardStep` — Colunas/etapas
- `FazerAi::Kanban::Task` — Cards/tarefas
- `FazerAi::Kanban::Product` — Produtos vinculados a tasks
- `FazerAi::Kanban::AuditEvent` — Log de auditoria
- `FazerAi::Kanban::AccountUserPreference` — Preferências por usuário

### Frontend Vue.js

| Pasta | Conteúdo |
|-------|---------|
| `fazer_ai/app/javascript/kanban/pages/` | 4 páginas Vue (Board, Settings, Overview, Products) |
| `fazer_ai/app/javascript/kanban/components/` | 17 componentes Vue |
| `fazer_ai/app/javascript/kanban/store/` | Vuex (actions, mutations, getters) |
| `fazer_ai/app/javascript/kanban/routes/` | Vue Router |
| `fazer_ai/app/javascript/kanban/api/` | Camada de API (boards, tasks, products, preferences) |

### Banco de Dados (12 tabelas)

```
kanban_boards
kanban_board_steps
kanban_board_agents
kanban_board_inboxes
kanban_tasks
kanban_task_agents
kanban_task_contacts
kanban_task_products
kanban_task_automations
kanban_products
kanban_audit_events
kanban_account_user_preferences
```

> A tabela `conversations` foi estendida com a coluna `kanban_task_id` (FK).

### Integração com o core Chatwoot

- `config/application.rb` — carrega a engine `fazer_ai/` dinamicamente se a pasta existir
- `config/routes.rb` — registra as rotas `/kanban`
- `config/features.yml` — feature flag `kanban`
- `lib/events/types.rb` — event types do Wisper para eventos kanban
- `lib/chatwoot_app.rb` — método `ChatwootApp.fazer_ai?` (checa se pasta existe)
- `vite.config.ts` — build do frontend inclui `fazer_ai/app/javascript`

---

## 3. Sistema de Licença e Assinatura

### Licença da `fazer_ai/`

```
The Chatwoot fazer.ai license
Copyright (c) 2025-2026 FAZER.AI LTDA
```

**Proibições explícitas:**
- ❌ Copiar
- ❌ Distribuir
- ❌ Sublicenciar
- ❌ Vender
- ❌ Remover a licença e colocar outra

**Permitido:**
- ✅ Uso para desenvolvimento e testes locais (sem assinatura)
- ✅ Modificar para uso próprio *com assinatura ativa*

### Sistema de autenticação do Kanban (`FazerAiHub`)

Todo acesso ao Kanban passa por esta verificação:

```ruby
def kanban_feature_enabled?
  feature_enabled?('kanban') &&          # feature flag no DB
  kanban_subscription_feature_accessible? # assinatura fazer.ai válida
end

def kanban_subscription_feature_accessible?
  FazerAiHub.subscription_active? &&       # assinatura ativa no fazer.ai
  FazerAiHub.feature_enabled?('kanban') && # kanban liberado no plano
  !FazerAiHub.kanban_account_limit.nil?    # limite configurado
end
```

O `FazerAiHub` valida um **JWT token** baixado de `https://app.fazer.ai`. Sem assinatura ativa, todos os endpoints retornam `404` e todos os listeners são no-ops.

---

## 4. Por que NÃO extrair o código da fazer_ai

1. **Ilegal**: A licença proíbe explicitamente copiar/redistribuir/sublicenciar
2. **Rastreável**: Nomes de classes, namespaces e histórico git provam a origem
3. **Trabalho quase equivalente**: Remover o sistema de assinatura (~30 pontos no código) + limpar rastros é quase o mesmo trabalho de construir do zero
4. **Risco legal**: A FAZER.AI LTDA tem copyright registrado e pode emitir takedown

---

## 5. Plano: Fork do Chatwoot OSS do zero

### 5.1 Licenças base

| Parte | Licença | Pode fazer fork? |
|-------|---------|-----------------|
| `app/` (core) | **MIT** | ✅ Sim, totalmente livre |
| `enterprise/` | Chatwoot Enterprise License | ⚠️ Verificar, geralmente não redistribuível |
| `fazer_ai/` | fazer.ai License | ❌ Não |

> **Use apenas o core MIT como base do seu fork.**

### 5.2 Passo a passo para criar o fork

**Passo 1 — Fork no GitHub**
```bash
# 1. Criar fork em: github.com/chatwoot/chatwoot → botão "Fork"
# 2. Clonar localmente
git clone https://github.com/SEU-USUARIO/chatwoot.git meu-chatwoot
cd meu-chatwoot

# 3. Adicionar upstream para receber atualizações do OSS
git remote add upstream https://github.com/chatwoot/chatwoot.git

# Verificar remotes
git remote -v
# origin   → seu fork (seu GitHub)
# upstream → chatwoot oficial
```

**Passo 2 — Estratégia de branches**
```
main         → sua versão production
dev          → desenvolvimento
feat/kanban  → feature kanban
feat/xxx     → outras features
```

```bash
git checkout -b dev
git push origin dev
```

**Passo 3 — Sync periódico com o Chatwoot oficial**
```bash
git fetch upstream
git checkout dev
git merge upstream/main
# resolver conflitos se houver
git push origin dev
```

> ⚠️ **Regra de ouro**: mantenha suas features em uma pasta/engine separada para minimizar conflitos com o upstream.

**Passo 4 — Criar sua engine privada**

Crie uma pasta com o nome do seu projeto (ex: `meu_app/`):

```
meu-chatwoot/
├── app/              → Chatwoot OSS (não mexa aqui se possível)
├── meu_app/          → ✅ SUA ENGINE PRIVADA
│   ├── app/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   ├── jobs/
│   │   ├── listeners/
│   │   └── javascript/
│   │       └── kanban/
│   ├── config/
│   ├── spec/
│   └── LICENSE       ← SUA licença
└── config/
    └── application.rb
```

**Passo 5 — Carregar a engine no `config/application.rb`**

```ruby
# Adicionar dentro do bloco Chatwoot::Application
meu_app_root = Rails.root.join('meu_app')
if meu_app_root.exist?
  config.eager_load_paths << meu_app_root.join('lib')
  config.eager_load_paths << meu_app_root.join('listeners')
  config.eager_load_paths += Dir["#{meu_app_root}/app/**"]
  config.paths['app/views'].unshift(meu_app_root.join('app/views').to_s)
end
```

**Passo 6 — Estrutura de licenças do seu fork**
```
LICENSE              → MIT (Chatwoot base — obrigatório manter atribuição)
meu_app/LICENSE      → Sua licença (pode ser proprietária, MIT, AGPL, etc.)
```

---

## 6. Kanban do zero: roadmap de construção

Use a arquitetura do `fazer_ai/` como **referência de design** (não de código):

### Fase 1 — Backend (prioridade alta)

| O que construir | Arquivo |
|----------------|---------|
| Migration: `kanban_boards` | `db/migrate/xxx_create_kanban_boards.rb` |
| Migration: `kanban_board_steps` | `db/migrate/xxx_create_kanban_board_steps.rb` |
| Migration: `kanban_tasks` | `db/migrate/xxx_create_kanban_tasks.rb` |
| Migration: coluna em `conversations` | `db/migrate/xxx_add_kanban_task_id_to_conversations.rb` |
| Model `Board` | `meu_app/app/models/kanban/board.rb` |
| Model `BoardStep` | `meu_app/app/models/kanban/board_step.rb` |
| Model `Task` | `meu_app/app/models/kanban/task.rb` |
| Feature flag `kanban` | `config/features.yml` |

### Fase 2 — API REST (prioridade média)

| Controller | Responsabilidade |
|-----------|-----------------|
| `boards_controller.rb` | CRUD de boards |
| `board_steps_controller.rb` | CRUD de etapas/colunas |
| `tasks_controller.rb` | CRUD + move de tasks |

### Fase 3 — Frontend Vue (prioridade média)

| Componente | Responsabilidade |
|-----------|-----------------|
| `KanbanBoard.vue` | Estrutura de colunas |
| `KanbanColumn.vue` | Coluna com drag-and-drop |
| `KanbanTaskCard.vue` | Card de tarefa |
| `KanbanTaskModal.vue` | Modal de detalhes |
| Vuex store | Estado global do kanban |
| Vue Router | Rotas do kanban |

### Fase 4 — Integração (prioridade baixa)

| O que construir | Propósito |
|----------------|----------|
| Listeners de eventos | Reagir a eventos do Chatwoot (ex: conversa criada) |
| Jobs de background | Webhooks, notificações de vencimento |
| Políticas Pundit | Autorização granular |
| Audit log | Log de ações |

---

## 7. Decisões a tomar na próxima conversa

- [ ] **Nome da engine privada** (ex: `meu_app/`, `minha_empresa/`, etc.)
- [ ] **Tipo de licença** para a engine (MIT, proprietária, AGPL?)
- [ ] **Nome do repositório** GitHub do fork
- [ ] **Quais features além do Kanban** você quer adicionar?
- [ ] **Autenticação do Kanban**: simples (feature flag no account) ou com planos/subscriptions próprios?
- [ ] **Drag and drop**: usar biblioteca Vue existente (vue-draggable, dnd-kit) ou custom?

---

## 8. Referências úteis

| Recurso | URL |
|---------|-----|
| Chatwoot OSS | https://github.com/chatwoot/chatwoot |
| Chatwoot Docs Dev | https://www.chatwoot.com/docs/contributing-guide |
| MIT License | https://opensource.org/licenses/MIT |
| Pundit (autorização Ruby) | https://github.com/varvet/pundit |
| Vue Draggable (drag-and-drop) | https://github.com/SortableJS/vue.draggable.next |
| FlagShihTzu (feature flags) | https://github.com/pboling/flag_shih_tzu |

---

> **Próximo passo recomendado:** Decidir o nome da engine e começar com as migrations + models do Board e Task. O agente pode gerar todo esse código do zero na próxima sessão.
