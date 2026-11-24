CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Tests", "bin/rails test"
  step "Autoloading", "bin/rails zeitwerk:check"
  step "Production assets", "env RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile"
end
