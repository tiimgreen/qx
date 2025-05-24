# Determine the Rails environment
rails_env = ENV.fetch("RAILS_ENV", "production")
environment rails_env

# Common configuration
threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
threads threads_count, threads_count

# Environment-specific configuration
case rails_env
when "production"
  # Production-specific settings
  workers ENV.fetch("WEB_CONCURRENCY") { 2 }


  app_dir = File.expand_path("../..", __FILE__)
  shared_dir = "#{app_dir}/shared"

  # Set socket permissions
  unix_socket_permissions = 0660

  # Use a UNIX socket for production
  bind "unix://#{shared_dir}/tmp/sockets/puma.sock"
  # Uncomment the following line if you need TCP binding as well
  bind "tcp://0.0.0.0:3050"

  # Specify the pidfile location
  pidfile "#{shared_dir}/tmp/pids/puma.pid"
  state_path "#{shared_dir}/tmp/pids/puma.state"

  stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true

  # Preload the application for performance
  preload_app!

when "development"
  # Development-specific settings
  worker_timeout 3600
  # Listen on port 3000 by default
  port ENV.fetch("PORT", 3000)
end

# Common settings for all environments
plugin :tmp_restart

# Optionally, you can add the following for better error handling:
lowlevel_error_handler do |e|
  Raven.capture_exception(e)
  [ 500, {}, [ "An error has occurred, and engineers have been informed. Please reload the page. If you continue to have problems, contact support@example.com\n" ] ]
end

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end
