# config valid for current version and patch releases of Capistrano
lock "~> 3.19.1"

server '52.66.200.87', port: 22, roles: [:web, :app, :db], primary: true

set :application, "authentication_app"
set :repo_url, "git@github.com:jayeshpatil01/authentication_app.git"

set :rbenv_ruby, '3.0.7'

set :branch, "main"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, '.env' #"config/database.yml", 'config/master.key'

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "vendor", "storage"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }
set :default_env, { path: "~/.rbenv/shims:~/.rbenv/bin:$PATH", NODE_OPTIONS: "--openssl-legacy-provider" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

set :user, 'ubuntu'
set :puma_threads, [4, 16]
set :puma_workers, 0

set :pty, true
set :user_sudo, false
set :stage, :production
set :deploy_via, :remote_cache
set :deploy_to, "/home/#{fetch(:user)}/#{fetch(:application)}"
set :puma_bind, "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.access.log"
set :puma_error_log, "#{release_path}/log/puma.error.log"
set :ssh_options, { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa), auth_methods: %w(publickey) }
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true   # change to false when not using active record

# Temporarily remove the --quiet flag from the bundler command
set :bundle_flags, '--jobs 4'

append :rbenv_map_bins, 'puma', 'pumactl'

namespace :puma do
  desc 'Create Directions for Pume PIDs and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

  before "deploy:starting", "puma:make_dirs"
end

namespace :deploy do
  desc "Make sure local git is in sync with remote"
  task :check_revision do
    on roles(:app) do

      # Update this to your branch name: master, main, etc. Here it's main
      unless `git rev-parse HEAD` == 'git rev-parse github/main'
        puts "WARNING: HEAD is not the same as github/main"
        puts "Run `git push` to sync changes."
        exit
      end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'puma:restart'
    end
  end

  # before :starting, :check_revision
  before :finishing, :compile_assets
  before :finishing, :cleanup

  desc 'Set correct permissions'
  task :set_permissions do
    on roles(:app) do
      execute :sudo, :chmod, '-R', '755', "#{shared_path}/tmp/sockets/authentication_app-puma.sock"
    end
  end

  after :publishing, :set_permissions
end
