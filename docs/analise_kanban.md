# 🗂️ Análise: Onde o Kanban está instalado

O Kanban **não está no core do Chatwoot OSS** — ele vive inteiramente dentro da pasta `fazer_ai/`, que funciona como um **engine Rails privado** montado sobre o Chatwoot base.

---

## 📦 Localização geral

```
e:\Nova pasta\chatwoot-modificado2\
└── fazer_ai/                   ← Engine privada (toda a feature Kanban fica aqui)
    ├── app/
    │   ├── controllers/
    │   ├── models/
    │   ├── services/
    │   ├── jobs/
    │   ├── listeners/
    │   ├── policies/
    │   ├── presenters/
    │   ├── views/
    │   └── javascript/kanban/  ← Frontend Vue completo
    ├── config/
    ├── lib/
    └── spec/
```

---

## 🗄️ Banco de Dados — Tabelas criadas

Todas com prefixo `kanban_`:

| Tabela | Descrição |
|--------|-----------|
| `kanban_boards` | Boards (pipelines) do kanban |
| `kanban_board_steps` | Colunas/etapas de um board |
| `kanban_board_agents` | Agentes vinculados a um board |
| `kanban_board_inboxes` | Inboxes vinculadas a um board |
| `kanban_tasks` | Tarefas (cards) do kanban |
| `kanban_task_agents` | Agentes responsáveis por uma task |
| `kanban_task_contacts` | Contatos vinculados a uma task |
| `kanban_task_products` | Produtos vinculados a uma task |
| `kanban_task_automations` | Automações vinculadas a uma task |
| `kanban_products` | Produtos do kanban |
| `kanban_audit_events` | Log de auditoria de ações |
| `kanban_account_user_preferences` | Preferências por usuário |

> A tabela `conversations` foi estendida com a coluna `kanban_task_id` (FK).

---

## 🔧 Backend — Ruby on Rails

### Models (`fazer_ai/app/models/fazer_ai/kanban/`)

- [board.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/models/fazer_ai/kanban/board.rb)
- [board_step.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/models/fazer_ai/kanban/board_step.rb)
- [board_agent.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/models/fazer_ai/kanban/board_agent.rb)
- [board_inbox.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/models/fazer_ai/kanban/board_inbox.rb)
- [task.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/models/fazer_ai/kanban/task.rb)
- [task_agent.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/models/fazer_ai/kanban/task_agent.rb)
- [task_contact.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/models/fazer_ai/kanban/task_contact.rb)
- [task_product.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/models/fazer_ai/kanban/task_product.rb)
- [task_automation.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/models/fazer_ai/kanban/task_automation.rb)
- [product.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/models/fazer_ai/kanban/product.rb)
- [audit_event.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/models/fazer_ai/kanban/audit_event.rb)
- [account_user_preference.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/models/fazer_ai/kanban/account_user_preference.rb)

### Controllers (`fazer_ai/app/controllers/api/v1/accounts/kanban/`)

- [base_controller.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/controllers/api/v1/accounts/kanban/base_controller.rb)
- [boards_controller.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/controllers/api/v1/accounts/kanban/boards_controller.rb)
- [board_steps_controller.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/controllers/api/v1/accounts/kanban/board_steps_controller.rb)
- [board_agents_controller.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/controllers/api/v1/accounts/kanban/board_agents_controller.rb)
- [board_inboxes_controller.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/controllers/api/v1/accounts/kanban/board_inboxes_controller.rb)
- [board_conversations_controller.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/controllers/api/v1/accounts/kanban/board_conversations_controller.rb)
- [tasks_controller.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/controllers/api/v1/accounts/kanban/tasks_controller.rb)
- [task_products_controller.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/controllers/api/v1/accounts/kanban/task_products_controller.rb)
- [products_controller.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/controllers/api/v1/accounts/kanban/products_controller.rb)
- [audit_events_controller.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/controllers/api/v1/accounts/kanban/audit_events_controller.rb)
- [account_user_preferences_controller.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/controllers/api/v1/accounts/kanban/account_user_preferences_controller.rb)

### Services (`fazer_ai/app/services/fazer_ai/kanban/`)

- [audit_logger.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/services/fazer_ai/kanban/audit_logger.rb)
- [board_round_robin_service.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/services/fazer_ai/kanban/board_round_robin_service.rb)
- [task_auto_assignment_service.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/services/fazer_ai/kanban/task_auto_assignment_service.rb)

### Jobs (`fazer_ai/app/jobs/fazer_ai/kanban/`)

- [audit_event_job.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/jobs/fazer_ai/kanban/audit_event_job.rb)
- [trigger_task_due_webhook_job.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/jobs/fazer_ai/kanban/trigger_task_due_webhook_job.rb)
- [trigger_task_due_webhooks_scheduler_job.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/jobs/fazer_ai/kanban/trigger_task_due_webhooks_scheduler_job.rb)

### Listeners (`fazer_ai/app/listeners/fazer_ai/`)

- [kanban_listener.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/listeners/fazer_ai/kanban_listener.rb) — Reage a eventos do sistema (ex: conversa criada → auto-move task)
- [kanban_automation_rule_listener.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/listeners/fazer_ai/kanban_automation_rule_listener.rb) — Executa regras de automação do Kanban
- [action_cable_listener.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/listeners/fazer_ai/action_cable_listener.rb) — Push em tempo real via WebSocket

### Policies (`fazer_ai/app/policies/fazer_ai/kanban/`)

- [application_policy.rb](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/policies/fazer_ai/kanban/application_policy.rb) — Política base
- Políticas específicas para board, task, product, step, audit_event, etc.

---

## 🖥️ Frontend — Vue.js

### Páginas (`fazer_ai/app/javascript/kanban/pages/`)

| Arquivo | Propósito |
|---------|-----------|
| [KanbanBoardPage.vue](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/pages/KanbanBoardPage.vue) | Página principal do board |
| [KanbanBoardSettingsPage.vue](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/pages/KanbanBoardSettingsPage.vue) | Configurações do board |
| [KanbanOverviewPage.vue](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/pages/KanbanOverviewPage.vue) | Visão geral / listagem de boards |
| [KanbanProductsPage.vue](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/pages/KanbanProductsPage.vue) | Gestão de produtos |

### Componentes (`fazer_ai/app/javascript/kanban/components/`)

17 componentes Vue, incluindo:
- [KanbanBoard.vue](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/components/KanbanBoard.vue) — Estrutura de colunas
- [KanbanColumn.vue](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/components/KanbanColumn.vue) — Coluna individual com drag-and-drop
- [KanbanTaskCard.vue](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/components/KanbanTaskCard.vue) — Card de task
- [KanbanTaskModal.vue](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/components/KanbanTaskModal.vue) — Modal de detalhes da task
- [KanbanConversationPanel.vue](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/components/KanbanConversationPanel.vue) — Painel de conversa integrada
- [KanbanBoardModal.vue](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/components/KanbanBoardModal.vue) — Criação/edição de board

### Estado (Vuex) (`fazer_ai/app/javascript/kanban/store/modules/kanban/`)

- [actions.js](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/store/modules/kanban/actions.js)
- [mutations.js](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/store/modules/kanban/mutations.js)
- [getters.js](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/store/modules/kanban/getters.js)

### Rotas (`fazer_ai/app/javascript/kanban/routes/index.js`)

- [index.js](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/routes/index.js)

### API Layer (`fazer_ai/app/javascript/kanban/api/`)

- [boards.js](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/api/boards.js)
- [tasks.js](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/api/tasks.js)
- [products.js](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/api/products.js)
- [taskProducts.js](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/api/taskProducts.js)
- [preferences.js](file:///e:/Nova%20pasta/chatwoot-modificado2/fazer_ai/app/javascript/kanban/api/preferences.js)

---

## 🔗 Integração com o Core Chatwoot

| Ponto de integração | Onde |
|---------------------|------|
| Feature flag `kanban` | `config/features.yml` + habilitado em `db/seeds.rb` |
| Coluna `kanban_task_id` em `conversations` | `db/schema.rb:724` |
| Rotas da API | `config/routes.rb` (namespace `/kanban`) |
| Swagger docs | `swagger/paths/application/kanban/` |
| Redis keys | `lib/redis/redis_keys.rb` |
| Event types | `lib/events/types.rb` |
| Scheduled jobs | `config/schedule.yml` |
| Frontend build | `vite.config.ts` (aponta para `fazer_ai/app/javascript`) |

---

## 🏗️ Arquitetura resumida

```
Chatwoot Core (OSS)
       │
       ├── config/routes.rb  ←──── registra rotas /kanban
       ├── db/schema.rb      ←──── tabelas kanban_*
       └── fazer_ai/ (Engine)
               ├── Backend (Rails MVC + Pundit + Wisper listeners)
               └── Frontend (Vue 3 + Vuex + Vue Router)
```

> **Resumo**: o Kanban é uma feature 100% proprietária da **fazer_ai engine**, completamente separada do OSS. Ele se integra ao Chatwoot base via rotas, feature flag, extensão do schema e event listeners.
