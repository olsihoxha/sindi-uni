#!/usr/bin/env bash
set -o errexit
bundle install
bundle exec rails assets:precompile
bundle exec rails db:migrate
# Explicit opt-in: seeds never run on an ordinary redeploy.
if [ "${SEED_DEMO_DATA:-false}" = "true" ]; then
  bundle exec rails db:seed
fi
