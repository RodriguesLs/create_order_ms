#!/bin/bash
set -e

# Aguarda o PostgreSQL estar pronto
until pg_isready -h $DATABASE_HOST -U $DATABASE_USERNAME; do
  echo "Aguardando o PostgreSQL..."
  sleep 2
done

# Executa migrações se existirem
bundle exec rails db:prepare

echo "Iniciando o Sidekiq..."
bundle exec sidekiq -C config/sidekiq.yml &

exec bundle exec rails server -b 0.0.0.0 -p 3000