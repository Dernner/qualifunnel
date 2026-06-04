# Kanban — Roadmap para paridade com o fazer_ai

## Contexto do projeto

Este projeto (`qualifunnel/`) é um fork do Chatwoot OSS com uma engine privada em `qualifunnel/`,
seguindo a mesma arquitetura da engine `fazer_ai/` do projeto `E:\Nova pasta\chatwoot-modificado2`.

O objetivo deste documento é servir de guia para implementar o Kanban do qualifunnel
com paridade funcional ao fazer_ai.

---

## Estado atual (o que já existe)

### Backend (`qualifunnel/`)
- `qualifunnel/app/models/qualifunnel/kanban/board.rb`
- `qualifunnel/app/models/qualifunnel/kanban/board_step.rb`
- `qualifunnel/app/models/qualifunnel/kanban/task.rb`
- `qualifunnel/app/models/qualifunnel/concerns/account.rb` — concern incluído no Account com `kanban_feature_enabled?` e `all_features` override
- `qualifunnel/app/controllers/api/v1/accounts/kanban/base_controller.rb`
- `qualifunnel/app/controllers/api/v1/accounts/kanban/boards_controller.rb` — com Pundit `authorize`
- `qualifunnel/app/controllers/api/v1/accounts/kanban/board_steps_controller.rb`
- `qualifunnel/app/controllers/api/v1/accounts/kanban/tasks_controller.rb`
- `qualifunnel/app/controllers/api/v1/accounts/kanban/account_user_preferences_controller.rb`
- `qualifunnel/app/policies/qualifunnel/kanban/application_policy.rb`
- `qualifunnel/app/policies/qualifunnel/kanban/board_policy.rb`
- `qualifunnel/config/initializers/account_extensions.rb` — inclui concerns no Account
- `qualifunnel/config/initializers/super_admin_extension.rb` — expõe kanban no Super Admin UI

### Migrations existentes
- `20260529205200_create_kanban_boards.rb`
- `20260529205201_create_kanban_board_steps.rb`
- `20260529205202_create_kanban_tasks.rb`
- `20260529205203_add_kanban_task_id_to_conversations.rb`
- `20260530130000_add_qualifunnel_flags_to_accounts.rb`
- `20260530140000_enable_kanban_for_all_accounts.rb` — seta default=1 e ativa para todas as contas

### Frontend (`qualifunnel/app/javascript/kanban/`)
- `routes/index.js` — com `meta.permissions` correto
- `store/modules/kanban/index.js`, `actions.js`, `mutations.js`
- `api/boards.js`, `api/tasks.js`
- `pages/KanbanOverviewPage.vue`, `pages/KanbanBoardPage.vue`
- `components/KanbanBoard.vue`, `KanbanColumn.vue`, `KanbanTaskCard.vue`

### Integração no core
- `app/javascript/dashboard/routes/dashboard/dashboard.routes.js` — rotas registradas
- `app/javascript/dashboard/store/index.js` — store registrada como `qualifunnel/kanban`
- `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` — item no sidebar com feature flag check
- `app/javascript/dashboard/featureFlags.js` — `KANBAN: 'kanban'`
- `vite.config.ts` — `server.watch.usePolling: true` (necessário para Docker no Windows)

### Decisões arquiteturais importantes
- **Feature flag**: usa coluna `qualifunnel_flags` (bigint separado) em vez da coluna padrão `feature_flags`.
  Motivo: `feature_flags` já tem 63 features, a 64ª causaria overflow no bigint do PostgreSQL.
- `kanban_feature_enabled?` usa `feature_kanban?` (bit 1 de `qualifunnel_flags`)
- `all_features` é sobrescrito no concern para incluir `'kanban' => feature_kanban?`
- Super Admin mostra o toggle via `Qualifunnel::SuperAdminAccountFeaturesExtension` (prepend no singleton)
- `AccountFlagInterceptor` intercepta `selected_feature_flags=` para rotear `feature_kanban` → `qualifunnel_flags`

---

## Desvios em relação ao fazer_ai (o que falta)

### FASE 1 — Migrations e models faltando (prerequisito de tudo)

#### 1.1 Colunas faltando em tabelas existentes

**`kanban_tasks`** — adicionar via migration:
```ruby
add_column :kanban_tasks, :priority, :integer, default: 0          # urgent/high/medium/low
add_column :kanban_tasks, :start_date, :datetime
add_column :kanban_tasks, :value, :decimal, precision: 15, scale: 2
add_column :kanban_tasks, :created_by_id, :bigint
add_column :kanban_tasks, :custom_attributes, :jsonb, default: {}
add_column :kanban_tasks, :cached_label_list, :text
add_column :kanban_tasks, :step_changed_at, :datetime
add_foreign_key :kanban_tasks, :users, column: :created_by_id
```

**`kanban_board_steps`** — adicionar via migration:
```ruby
add_column :kanban_board_steps, :probability, :decimal, precision: 5, scale: 2, default: 0
add_column :kanban_board_steps, :color, :string
add_column :kanban_board_steps, :description, :text
add_column :kanban_board_steps, :tasks_count, :integer, default: 0, null: false   # counter cache
```

**`kanban_boards`** — adicionar via migration:
```ruby
add_column :kanban_boards, :currency, :string, default: 'USD'
add_column :kanban_boards, :steps_order, :integer, array: true, default: []
```

#### 1.2 Novas tabelas e models

**`kanban_task_agents`** (join table tasks ↔ users):
```ruby
create_table :kanban_task_agents do |t|
  t.references :task, null: false, foreign_key: { to_table: :kanban_tasks }
  t.references :agent, null: false, foreign_key: { to_table: :users }
  t.timestamps
  t.index [:task_id, :agent_id], unique: true
end
```
Model: `Qualifunnel::Kanban::TaskAgent`

**`kanban_task_contacts`** (join table tasks ↔ contacts):
```ruby
create_table :kanban_task_contacts do |t|
  t.references :task, null: false, foreign_key: { to_table: :kanban_tasks }
  t.references :contact, null: false, foreign_key: true
  t.timestamps
  t.index [:task_id, :contact_id], unique: true
end
```
Model: `Qualifunnel::Kanban::TaskContact`

**`kanban_board_agents`** (join table boards ↔ users — controle de acesso):
```ruby
create_table :kanban_board_agents do |t|
  t.references :board, null: false, foreign_key: { to_table: :kanban_boards }
  t.references :agent, null: false, foreign_key: { to_table: :users }
  t.timestamps
  t.index [:board_id, :agent_id], unique: true
end
```
Model: `Qualifunnel::Kanban::BoardAgent`

**`kanban_board_inboxes`** (join table boards ↔ inboxes):
```ruby
create_table :kanban_board_inboxes do |t|
  t.references :board, null: false, foreign_key: { to_table: :kanban_boards }
  t.references :inbox, null: false, foreign_key: true
  t.timestamps
  t.index [:board_id, :inbox_id], unique: true
end
```
Model: `Qualifunnel::Kanban::BoardInbox`

**`kanban_products`** (catálogo de produtos por board):
```ruby
create_table :kanban_products do |t|
  t.references :board, null: false, foreign_key: { to_table: :kanban_boards }
  t.string :name, null: false
  t.decimal :unit_price, precision: 15, scale: 2, default: 0
  t.text :description
  t.boolean :archived, default: false
  t.timestamps
end
```
Model: `Qualifunnel::Kanban::Product`

**`kanban_task_products`** (itens de linha por task):
```ruby
create_table :kanban_task_products do |t|
  t.references :task, null: false, foreign_key: { to_table: :kanban_tasks }
  t.references :product, null: false, foreign_key: { to_table: :kanban_products }
  t.integer :quantity, default: 1
  t.decimal :unit_price, precision: 15, scale: 2, default: 0
  t.decimal :discount_percentage, precision: 5, scale: 2, default: 0
  t.timestamps
end
```
Model: `Qualifunnel::Kanban::TaskProduct`

**`kanban_audit_events`** (histórico de ações):
```ruby
create_table :kanban_audit_events do |t|
  t.references :account, null: false, foreign_key: true
  t.references :task, null: false, foreign_key: { to_table: :kanban_tasks }
  t.bigint :performed_by_id
  t.string :action, null: false
  t.jsonb :metadata, default: {}
  t.timestamps
  t.foreign_key :users, column: :performed_by_id
end
```
Model: `Qualifunnel::Kanban::AuditEvent`

**`kanban_account_user_preferences`** (preferências por usuário):
```ruby
create_table :kanban_account_user_preferences do |t|
  t.references :account_user, null: false, foreign_key: true
  t.jsonb :preferences, default: {}
  t.timestamps
  t.index :account_user_id, unique: true
end
```
Model: `Qualifunnel::Kanban::AccountUserPreference`
Preferences jsonb inclui: `board_sorting`, `favorite_board_ids`, `tasks_order`, `task_sorting`

---

### FASE 2 — Concerns em models core

Criar arquivo `qualifunnel/app/models/qualifunnel/concerns/account_user.rb`:
```ruby
module Qualifunnel::Concerns::AccountUser
  extend ActiveSupport::Concern
  included do
    has_many :kanban_assigned_tasks, through: :kanban_task_agents, ...
    has_many :kanban_created_tasks, class_name: 'Qualifunnel::Kanban::Task', foreign_key: :created_by_id
    has_many :kanban_board_agents, class_name: 'Qualifunnel::Kanban::BoardAgent'
    has_many :kanban_audit_events, class_name: 'Qualifunnel::Kanban::AuditEvent'
    has_one :kanban_preference, class_name: 'Qualifunnel::Kanban::AccountUserPreference'
  end
end
```

Criar `qualifunnel/app/models/qualifunnel/concerns/conversation.rb`:
```ruby
module Qualifunnel::Concerns::Conversation
  extend ActiveSupport::Concern
  included do
    belongs_to :kanban_task, class_name: 'Qualifunnel::Kanban::Task', optional: true
  end
end
```

Criar `qualifunnel/app/models/qualifunnel/concerns/inbox.rb`:
```ruby
module Qualifunnel::Concerns::Inbox
  extend ActiveSupport::Concern
  included do
    has_many :kanban_board_inboxes, class_name: 'Qualifunnel::Kanban::BoardInbox'
    has_many :kanban_boards, through: :kanban_board_inboxes
  end
end
```

Criar `qualifunnel/app/models/qualifunnel/concerns/contact.rb`:
```ruby
module Qualifunnel::Concerns::Contact
  extend ActiveSupport::Concern
  included do
    has_many :kanban_task_contacts, class_name: 'Qualifunnel::Kanban::TaskContact'
    has_many :kanban_tasks, through: :kanban_task_contacts
  end
end
```

Atualizar `qualifunnel/config/initializers/account_extensions.rb` para incluir os novos concerns:
```ruby
Rails.application.config.to_prepare do
  Account.include Qualifunnel::Concerns::Account
  Account.prepend Qualifunnel::Concerns::AccountFlagInterceptor
  AccountUser.include Qualifunnel::Concerns::AccountUser
  Conversation.include Qualifunnel::Concerns::Conversation
  Inbox.include Qualifunnel::Concerns::Inbox
  Contact.include Qualifunnel::Concerns::Contact
end
```

---

### FASE 3 — API (controllers + routes + jbuilder views)

#### 3.1 Controllers novos a criar

- `qualifunnel/app/controllers/api/v1/accounts/kanban/board_agents_controller.rb`
  - `index`, `create`, `destroy`, `update_agents` (batch)
- `qualifunnel/app/controllers/api/v1/accounts/kanban/board_inboxes_controller.rb`
  - `index`, `create`, `destroy`, `update_inboxes` (batch)
- `qualifunnel/app/controllers/api/v1/accounts/kanban/board_conversations_controller.rb`
  - `index` (conversas vinculadas ao board)
- `qualifunnel/app/controllers/api/v1/accounts/kanban/products_controller.rb`
  - CRUD completo por board
- `qualifunnel/app/controllers/api/v1/accounts/kanban/task_products_controller.rb`
  - CRUD completo por task
- `qualifunnel/app/controllers/api/v1/accounts/kanban/audit_events_controller.rb`
  - `index`, `show` por task

#### 3.2 Routes a adicionar em `config/routes.rb`

O namespace kanban já existe. Adicionar dentro dele:
```ruby
namespace :kanban do
  resource :account_user_preferences, only: [:update]
  resources :boards do
    resources :steps, controller: 'board_steps', only: [:index, :show, :create, :update, :destroy]
    resources :agents, controller: 'board_agents', only: [:index, :create, :destroy]
    resources :inboxes, controller: 'board_inboxes', only: [:index, :create, :destroy]
    resources :conversations, controller: 'board_conversations', only: [:index]
    resources :products, controller: 'products', only: [:index, :create, :update, :destroy]
    post :update_agents, on: :member
    post :update_inboxes, on: :member
    post :toggle_favorite, on: :member
  end
  resources :tasks do
    post :move, on: :member
    resources :audit_events, controller: 'audit_events', only: [:index, :show]
    resources :products, controller: 'task_products', only: [:index, :create, :update, :destroy]
  end
end
```

#### 3.3 Jbuilder views

Criar estrutura em `qualifunnel/app/views/api/v1/accounts/kanban/` com:
- `boards/index.json.jbuilder`, `boards/show.json.jbuilder`, `boards/_board.json.jbuilder`
- `board_steps/index.json.jbuilder`, `board_steps/_step.json.jbuilder`
- `tasks/index.json.jbuilder`, `tasks/show.json.jbuilder`, `tasks/_task.json.jbuilder`
- `audit_events/index.json.jbuilder`, `audit_events/_audit_event.json.jbuilder`
- `products/index.json.jbuilder`, `products/_product.json.jbuilder`

#### 3.4 Policies faltando

- `qualifunnel/app/policies/qualifunnel/kanban/board_step_policy.rb`
- `qualifunnel/app/policies/qualifunnel/kanban/task_policy.rb`
- `qualifunnel/app/policies/qualifunnel/kanban/board_agent_policy.rb`
- `qualifunnel/app/policies/qualifunnel/kanban/board_inbox_policy.rb`
- `qualifunnel/app/policies/qualifunnel/kanban/product_policy.rb`
- `qualifunnel/app/policies/qualifunnel/kanban/audit_event_policy.rb`
- `qualifunnel/app/policies/qualifunnel/kanban/account_user_preference_policy.rb`

Também adicionar `authorize` nos controllers de steps e tasks (já existem mas ainda sem Pundit).

---

### FASE 4 — Listeners e jobs (tempo real + webhooks)

#### 4.1 Listeners

Criar `qualifunnel/app/listeners/qualifunnel/kanban_listener.rb`:
- Escuta eventos `kanban_board_created`, `kanban_board_updated`
- Escuta `kanban_task_created`, `kanban_task_updated`, `kanban_task_completed`, `kanban_task_deleted`
- Dispara jobs de auditoria e webhooks

Criar `qualifunnel/app/listeners/qualifunnel/action_cable_listener.rb`:
- Transmite via ActionCable quando tasks/boards são criados/atualizados
- Permite atualização em tempo real no frontend

Registrar listeners em `qualifunnel/tasks_railtie.rb` (criar arquivo seguindo o padrão do fazer_ai).

#### 4.2 Jobs

- `qualifunnel/app/jobs/qualifunnel/kanban/audit_event_job.rb` — loga ações assincronamente
- `qualifunnel/app/jobs/qualifunnel/kanban/trigger_task_due_webhook_job.rb` — notifica tasks vencidas
- `qualifunnel/app/jobs/qualifunnel/kanban/trigger_task_due_webhooks_scheduler_job.rb` — agendador

---

### FASE 5 — Services (lógica de negócio avançada)

- `qualifunnel/app/services/qualifunnel/kanban/audit_logger.rb`
- `qualifunnel/app/services/qualifunnel/kanban/board_round_robin_service.rb` — distribuição automática
- `qualifunnel/app/services/qualifunnel/kanban/task_auto_assignment_service.rb`
- `qualifunnel/app/services/qualifunnel/automation_rules/kanban_action_service.rb`
- `qualifunnel/app/services/qualifunnel/automation_rules/kanban_conditions_filter_service.rb`

---

### FASE 6 — Frontend completo

#### 6.1 Vuex Store
- Adicionar `getters.js` com getters derivados (tasks por step, total de valor, etc.)
- Adicionar `mutation-types.js` com constantes de mutations

#### 6.2 API layer faltando
- `qualifunnel/app/javascript/kanban/api/products.js`
- `qualifunnel/app/javascript/kanban/api/taskProducts.js`
- `qualifunnel/app/javascript/kanban/api/preferences.js`

#### 6.3 Composables
- `qualifunnel/app/javascript/kanban/composables/useKanban.js`
- `qualifunnel/app/javascript/kanban/composables/useBoardModal.js`
- `qualifunnel/app/javascript/kanban/composables/useTaskProducts.js`

#### 6.4 Componentes faltando
- `KanbanTaskModal.vue` — abre/edita detalhes completos da task (agentes, contatos, data, valor)
- `KanbanBoardModal.vue` — criar/editar board
- `KanbanStepModal.vue` — criar/editar etapa
- `KanbanBoardSwitcher.vue` — troca rápida entre boards
- `KanbanContextDropdown.vue` — menu de contexto nas tasks
- `KanbanTaskProductsPanel.vue` — itens de linha na task
- `KanbanDeleteTaskDialog.vue` — confirmação de deleção

#### 6.5 Páginas faltando
- `KanbanBoardSettingsPage.vue` — configura agentes, inboxes, automações do board
- `KanbanProductsPage.vue` — catálogo de produtos do board

#### 6.6 i18n
- Extrair todas as strings hardcoded em PT-BR dos componentes Vue
- Criar `app/javascript/dashboard/i18n/locale/en/kanban.json`
- Criar `app/javascript/dashboard/i18n/locale/pt_BR/kanban.json`

---

## Ordem de execução recomendada

```
Fase 1 (migrations + models)
    ↓
Fase 2 (concerns nos models core)
    ↓
Fase 3 (controllers + routes + views + policies)
    ↓
Fase 6 parcial (KanbanTaskModal + i18n — o que mais impacta o usuário)
    ↓
Fase 4 (listeners + jobs — tempo real)
    ↓
Fase 5 (services — automações e lógica avançada)
    ↓
Fase 6 completo (páginas de settings, produtos, composables)
```

---

## Referência: projeto fazer_ai

Localização: `E:\Nova pasta\chatwoot-modificado2`
Engine: `fazer_ai/`
Namespace Ruby: `FazerAi::`

Use esse projeto como referência de implementação. **Não copiar código** — apenas usar como
guia arquitetural e de padrões. O namespace e a lógica de assinatura do fazer_ai são diferentes
e não devem ser replicados.

---

## Comandos úteis (Docker)

```bash
# Reiniciar containers após mudanças de código
docker compose restart rails vite

# Rodar migrations
docker compose exec rails bundle exec rails db:migrate

# Verificar rotas do kanban
docker compose exec rails bundle exec rails routes | grep kanban

# Rodar specs do qualifunnel
docker compose exec rails bundle exec rspec qualifunnel/spec/

# Verificar que o kanban está ativo para um account
docker compose exec rails bundle exec rails runner "puts Account.first.enabled_features.to_json"
```
