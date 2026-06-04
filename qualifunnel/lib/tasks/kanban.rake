# frozen_string_literal: true

namespace :qualifunnel do
  namespace :kanban do
    desc 'Ativa a feature Kanban para todos os accounts ativos'
    task enable_all: :environment do
      count = Account.where(status: :active).update_all('qualifunnel_flags = qualifunnel_flags | 1')
      puts "Kanban ativado para #{count} account(s)."
    end

    desc 'Ativa a feature Kanban para um account específico (uso: rake qualifunnel:kanban:enable[ACCOUNT_ID])'
    task :enable, [:account_id] => :environment do |_t, args|
      account = Account.find(args[:account_id])
      account.update!(qualifunnel_flags: account.qualifunnel_flags | 1)
      puts "Kanban ativado para o account ##{account.id} (#{account.name})."
    end

    desc 'Desativa a feature Kanban para um account específico (uso: rake qualifunnel:kanban:disable[ACCOUNT_ID])'
    task :disable, [:account_id] => :environment do |_t, args|
      account = Account.find(args[:account_id])
      account.update!(qualifunnel_flags: account.qualifunnel_flags & ~1)
      puts "Kanban desativado para o account ##{account.id} (#{account.name})."
    end
  end
end
