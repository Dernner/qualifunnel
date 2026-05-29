# Fork do Chatwoot com Engine Própria (`meu_app/`)

## Objetivo

Criar um fork do Chatwoot OSS (MIT) com uma engine privada chamada `meu_app/` seguindo **exatamente a mesma estrutura arquitetural do `fazer_ai/`**, mas com código 100% próprio. O primeiro feature a construir será o **Kanban**.

---

## User Review Required

> [!IMPORTANT]
> Este plano cria código do zero — nenhuma linha do `fazer_ai/` será copiada.
> A arquitetura é inspirada no padrão do fazer_ai, que é a forma correta de estender o Chatwoot.

> [!WARNING]
> A pasta `fazer_ai/` presente no projeto atual **não será tocada**. O trabalho acontece em um novo repositório, fork do Chatwoot OSS oficial (`github.com/chatwoot/chatwoot`).

---

## Open Questions

> [!IMPORTANT]
> Antes de executar, confirme:
> - **Nome do GitHub**: qual seu usuário no GitHub? (para montar a URL do fork)
> - **Nome do projeto/produto**: o que você quer chamar sua plataforma? (ex: "MinhaPlataforma", "MeuChat", etc.) — isso vai no LICENSE e nas classes Ruby
> - **Namespace Ruby**: como chamar o módulo principal? (sugerido: `MeuApp`, mas pode ser qualquer coisa)

---

## Arquitetura Proposta

Seguindo o mesmo padrão do `fazer_ai/`:

```
chatwoot-fork/                         ← fork do chatwoot/chatwoot (MIT)
├── app/                               → Chatwoot OSS — NÃO MEXER
├── config/
│   ├── application.rb                 → [MODIFY] adicionar carregamento da meu_app/
│   ├── routes.rb                      → [MODIFY] adicionar namespace :kanban
│   └── features.yml                   → [MODIFY] adicionar feature flag `kanban`
├── meu_app/                           → [NEW] engine privada
│   ├── LICENSE                        → [NEW] sua licença proprietária
│   ├── app/
│   │   ├── controllers/
│   │   │   └── api/v1/accounts/kanban/
│   │   │       ├── base_controller.rb
│   │   │       ├── boards_controller.rb
│   │   │       ├── board_steps_controller.rb
│   │   │       ├── tasks_controller.rb
│   │   │       └── account_user_preferences_controller.rb
│   │   ├── models/
│   │   │   └── meu_app/
│   │   │       ├── concerns/
│   │   │       │   └── account.rb     → adiciona kanban_feature_enabled? ao Account
│   │   │       └── kanban/
│   │   │           ├── board.rb
│   │   │           ├── board_step.rb
│   │   │           └── task.rb
│   │   ├── policies/
│   │   │   └── meu_app/kanban/
│   │   │       ├── application_policy.rb
│   │   │       └── board_policy.rb
│   │   └── javascript/
│   │       └── kanban/
│   │           ├── pages/
│   │           │   ├── KanbanBoardPage.vue
│   │           │   └── KanbanOverviewPage.vue
│   │           ├── components/
│   │           │   ├── KanbanBoard.vue
│   │           │   ├── KanbanColumn.vue
│   │           │   └── KanbanTaskCard.vue
│   │           ├── store/
│   │           │   └── modules/kanban/
│   │           │       ├── index.js
│   │           │       ├── actions.js
│   │           │       └── mutations.js
│   │           ├── api/
│   │           │   ├── boards.js
│   │           │   └── tasks.js
│   │           └── routes/
│   │               └── index.js
│   └── spec/
│       ├── models/meu_app/kanban/
│       └── requests/api/v1/accounts/kanban/
└── db/
    └── migrate/
        ├── xxx_create_kanban_boards.rb
        ├── xxx_create_kanban_board_steps.rb
        ├── xxx_create_kanban_tasks.rb
        └── xxx_add_kanban_task_id_to_conversations.rb
```

---

## Proposed Changes

### Fase 1 — Fork e estrutura base

#### Passo 1: Fork no GitHub
```bash
# 1. Acessar: https://github.com/chatwoot/chatwoot → "Fork"
# 2. Clonar localmente
git clone https://github.com/SEU-USUARIO/chatwoot.git chatwoot-fork
cd chatwoot-fork

# 3. Adicionar upstream
git remote add upstream https://github.com/chatwoot/chatwoot.git
git remote -v
```

#### Passo 2: Branch de trabalho
```bash
git checkout -b dev
git push origin dev
```

---

### Fase 2 — Arquivos de integração no core

#### [MODIFY] `config/application.rb`
Adicionar bloco de carregamento da engine `meu_app/` (igual ao pattern do fazer_ai):

```ruby
meu_app_root = Rails.root.join('meu_app')
if meu_app_root.exist?
  config.eager_load_paths << meu_app_root.join('lib')
  config.eager_load_paths << meu_app_root.join('listeners')
  config.eager_load_paths += Dir["#{meu_app_root}/app/**"]
  config.paths['app/views'].unshift(meu_app_root.join('app/views').to_s)

  meu_app_initializers = meu_app_root.join('config/initializers')
  Dir[meu_app_initializers.join('**/*.rb')].each { |f| require f } if meu_app_initializers.exist?
end
```

#### [MODIFY] `lib/chatwoot_app.rb`
Adicionar método `meu_app?`:
```ruby
def self.meu_app?
  return false if ENV.fetch('DISABLE_MEU_APP', false)
  @meu_app ||= root.join('meu_app').exist?
end
```

#### [MODIFY] `config/features.yml`
Adicionar a feature flag do kanban (sem a tag `fazer_ai`):
```yaml
- name: kanban
  display_name: Kanban
  enabled: false
  meu_app: true
```

> [!WARNING]
> O `features.yml` usa posição de bit (FlagShihTzu). **NUNCA reordenar** entradas existentes — só adicionar ao final para não corromper feature flags existentes das contas.

#### [MODIFY] `config/routes.rb`
Adicionar namespace kanban dentro do bloco de accounts:
```ruby
namespace :kanban do
  resource :account_user_preferences, only: [:update]
  resources :boards do
    resources :steps, controller: 'board_steps', only: [:index, :show, :create, :update, :destroy]
    resources :tasks, only: [:index, :create, :update, :destroy]
    post :toggle_favorite, on: :member
  end
  resources :tasks do
    post :move, on: :member
  end
end
```

---

### Fase 3 — Engine `meu_app/`

#### [NEW] `meu_app/LICENSE`
Sua licença proprietária (similar ao padrão fazer_ai, mas com seu copyright).

#### [NEW] Migrations do banco de dados

**`kanban_boards`:**
```ruby
create_table :kanban_boards do |t|
  t.references :account, null: false, foreign_key: true
  t.string :name, null: false
  t.text :description
  t.jsonb :settings, default: {}
  t.timestamps
  t.index [:account_id, :name], unique: true
end
```

**`kanban_board_steps`:**
```ruby
create_table :kanban_board_steps do |t|
  t.references :board, null: false, foreign_key: { to_table: :kanban_boards }
  t.string :name, null: false
  t.integer :position, null: false, default: 0
  t.boolean :completed, default: false
  t.boolean :cancelled, default: false
  t.timestamps
  t.index :board_id
end
```

**`kanban_tasks`:**
```ruby
create_table :kanban_tasks do |t|
  t.references :account, null: false, foreign_key: true
  t.references :board, null: false, foreign_key: { to_table: :kanban_boards }
  t.references :board_step, null: false, foreign_key: { to_table: :kanban_board_steps }
  t.string :title, null: false
  t.text :description
  t.integer :position, default: 0
  t.datetime :due_date
  t.timestamps
end
```

**Adicionar coluna em conversations:**
```ruby
add_column :conversations, :kanban_task_id, :bigint
add_foreign_key :conversations, :kanban_tasks
add_index :conversations, :kanban_task_id
```

#### [NEW] Models

**`meu_app/app/models/meu_app/kanban/board.rb`:**
```ruby
module MeuApp
  module Kanban
    class Board < ApplicationRecord
      self.table_name = 'kanban_boards'
      belongs_to :account
      has_many :steps, class_name: 'MeuApp::Kanban::BoardStep', dependent: :destroy
      has_many :tasks, class_name: 'MeuApp::Kanban::Task', dependent: :destroy
      validates :name, presence: true, uniqueness: { scope: :account_id }
    end
  end
end
```

**`meu_app/app/models/meu_app/concerns/account.rb`:**
```ruby
module MeuApp::Concerns::Account
  extend ActiveSupport::Concern
  included do
    has_many :kanban_boards,
             class_name: 'MeuApp::Kanban::Board',
             dependent: :destroy_async
  end

  def kanban_feature_enabled?
    feature_enabled?('kanban')
    # Sem validação de assinatura — feature livre no seu fork
  end
end
```

#### [NEW] Controllers

**`meu_app/app/controllers/api/v1/accounts/kanban/base_controller.rb`:**
```ruby
class Api::V1::Accounts::Kanban::BaseController < Api::V1::Accounts::BaseController
  before_action :ensure_kanban_feature_enabled

  private

  def ensure_kanban_feature_enabled
    return if Current.account&.kanban_feature_enabled?
    head :not_found
  end
end
```

#### [NEW] Frontend Vue

Estrutura mínima viável:
- `KanbanOverviewPage.vue` — listagem de boards
- `KanbanBoardPage.vue` — board com colunas e cards
- `KanbanBoard.vue` — componente de colunas
- `KanbanColumn.vue` — coluna com drag-and-drop
- `KanbanTaskCard.vue` — card de tarefa

---

## Diferenças chave em relação ao fazer_ai

| Aspecto | fazer_ai | Seu fork (meu_app) |
|---------|----------|--------------------|
| Namespace Ruby | `FazerAi::Kanban::` | `MeuApp::Kanban::` |
| Gate de feature | `kanban_feature_enabled?` = feature flag **+** assinatura paga | `kanban_feature_enabled?` = só feature flag (gratuito) |
| Sistema de assinatura | `FazerAiHub` (JWT do fazer.ai) | **Não existe** — você controla |
| Licença | fazer.ai License | Sua licença |
| Limite de contas | Limitado por plano | Sem limite |

---

## Verification Plan

### Após cada fase

```bash
# Verificar que a engine carrega
bundle exec rails runner "puts ChatwootApp.meu_app?"
# => true

# Rodar migrations
bundle exec rails db:migrate

# Verificar rotas
bundle exec rails routes | grep kanban

# Rodar specs
bundle exec rspec meu_app/spec/

# Lint Ruby
bundle exec rubocop meu_app/

# Build frontend
pnpm dev
```

### Manual
1. Acessar o Chatwoot local
2. Habilitar feature `kanban` via Super Admin → Accounts
3. Verificar que o menu Kanban aparece na sidebar
4. Criar um board, adicionar steps e tasks

---

## Ordem de execução

- [ ] **Fase 1**: Fork no GitHub + clone + setup remotes
- [ ] **Fase 2**: Modificar `application.rb`, `chatwoot_app.rb`, `features.yml`, `routes.rb`
- [ ] **Fase 3**: Criar `meu_app/LICENSE`
- [ ] **Fase 4**: Criar migrations (kanban_boards, board_steps, tasks, conversations)
- [ ] **Fase 5**: Criar models (Board, BoardStep, Task, Concerns::Account)
- [ ] **Fase 6**: Criar controllers (base + boards + tasks)
- [ ] **Fase 7**: Criar frontend Vue (páginas + componentes + store + rotas)
- [ ] **Fase 8**: Criar specs básicas
- [ ] **Fase 9**: Verificação completa
