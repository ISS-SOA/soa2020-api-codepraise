# frozen_string_literal: true

require 'rake/testtask'

task :default do
  puts `rake -T`
end

desc 'Run unit and integration tests'
Rake::TestTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.warning = false
end

# NOTE: run `rake run:test` in another process
desc 'Run acceptance tests'
Rake::TestTask.new(:spec_accept) do |t|
  t.pattern = 'spec/tests_acceptance/*_acceptance.rb'
  t.warning = false
end

desc 'Keep rerunning unit/integration tests upon changes'
task :respec do
  sh "rerun -c 'rake spec' --ignore 'coverage/*'"
end

desc 'Keep restarting web app upon changes'
task :rerack do
  sh "rerun -c 'puma config.ru -p 9090' --ignore 'coverage/*'"
end

namespace :api do
  namespace :run do
    desc 'Run API in dev mode'
    task :dev do
      sh 'puma config.ru -p 9090'
    end

    desc 'Run API in test mode'
    task :test do
      sh 'RACK_ENV=test puma config.ru -p 9090'
    end
  end
end

namespace :db do
  task :config do
    require 'sequel'
    require_relative 'config/environment' # load config info

    @app = CodePraise::App
  end

  desc 'Run migrations'
  task :migrate => :config do
    Sequel.extension :migration
    puts "Migrating #{@app.environment} database to latest"
    Sequel::Migrator.run(@app.DB, 'app/infrastructure/database/migrations')
  end

  desc 'Wipe records from all tables'
  task :wipe => :config do
    require_relative 'spec/helpers/database_helper'
    DatabaseHelper.setup_database_cleaner
    DatabaseHelper.wipe_database
  end

  desc 'Delete dev or test database file'
  task :drop => :config do
    if @app.environment == :production
      puts 'Cannot remove production database!'
      return
    end

    FileUtils.rm(@app.config.DB_FILENAME)
    puts "Deleted #{@app.config.DB_FILENAME}"
  end
end

namespace :repostore do
  task :config do
    require_relative 'config/environment' # load config info
    @app = CodePraise::App
  end

  desc 'Create director for repo store'
  task :create => :config do
    puts `mkdir #{@app.config.REPOSTORE_PATH}`
  end

  desc 'Delete cloned repos in repo store'
  task :wipe => :config do
    sh "rm -rf #{@app.config.REPOSTORE_PATH}/*" do |ok, _|
      puts(ok ? 'Cloned repos deleted' : 'Could not delete cloned repos')
    end
  end

  desc 'List cloned repos in repo store'
  task :list => :config do
    puts `ls #{@app.config.REPOSTORE_PATH}`
  end
end

namespace :cache do
  task :config do
    require_relative 'config/environment' # load config info
    require_relative 'app/infrastructure/cache/init' # load cache client
    @api = CodePraise::App
  end

  desc 'Directory listing of local dev cache'
  namespace :list do
    task :dev do
      puts 'Lists development cache'
      list = `ls _cache`
      puts 'No local cache found' if list.empty?
      puts list
    end

    desc 'Lists production cache'
    task :production => :config do
      puts 'Finding production cache'
      keys = CodePraise::Cache::Client.new(@api.config).keys
      puts 'No keys found' if keys.none?
      keys.each { |key| puts "Key: #{key}" }
    end
  end

  namespace :wipe do
    desc 'Delete development cache'
    task :dev do
      puts 'Deleting development cache'
      sh 'rm -rf _cache/*'
    end

    desc 'Delete production cache'
    task :production => :config do
      print 'Are you sure you wish to wipe the production cache? (y/n) '
      if $stdin.gets.chomp.downcase == 'y'
        puts 'Deleting production cache'
        wiped = CodePraise::Cache::Client.new(@api.config).wipe
        wiped.each_key { |key| puts "Wiped: #{key}" }
      end
    end
  end
end

namespace :queues do
  task :config do
    require 'aws-sdk-sqs'
    require_relative 'config/environment' # load config info
    @api = CodePraise::App

    @sqs = Aws::SQS::Client.new(
      access_key_id: @api.config.AWS_ACCESS_KEY_ID,
      secret_access_key: @api.config.AWS_SECRET_ACCESS_KEY,
      region: @api.config.AWS_REGION
    )
  end

  desc 'Create SQS queue for worker'
  task :create => :config do
    puts "Environment: #{@api.environment}"
    @sqs.create_queue(queue_name: @api.config.CLONE_QUEUE)

    q_url = @sqs.get_queue_url(queue_name: @api.config.CLONE_QUEUE).queue_url
    puts 'Queue created:'
    puts "  Name: #{@api.config.CLONE_QUEUE}"
    puts "  Region: #{@api.config.AWS_REGION}"
    puts "  URL: #{q_url}"
  rescue StandardError => e
    puts "Error creating queue: #{e}"
  end

  desc 'Report status of queue for worker'
  task :status => :config do
    q_url = @sqs.get_queue_url(queue_name: @api.config.CLONE_QUEUE).queue_url

    puts "Environment: #{@api.environment}"
    puts 'Queue info:'
    puts "  Name: #{@api.config.CLONE_QUEUE}"
    puts "  Region: #{@api.config.AWS_REGION}"
    puts "  URL: #{q_url}"
  rescue StandardError => e
    puts "Error finding queue: #{e}"
  end

  desc 'Purge messages in SQS queue for worker'
  task :purge => :config do
    q_url = @sqs.get_queue_url(queue_name: @api.config.CLONE_QUEUE).queue_url
    @sqs.purge_queue(queue_url: q_url)
    puts "Queue #{@api.config.CLONE_QUEUE} purged"
  rescue StandardError => e
    puts "Error purging queue: #{e}"
  end
end

namespace :worker do
  namespace :run do
    desc 'Run the background cloning worker in development mode'
    task :dev => :config do
      sh 'RACK_ENV=development bundle exec shoryuken -r ./workers/git_clone_worker.rb -C ./workers/shoryuken_dev.yml'
    end

    desc 'Run the background cloning worker in testing mode'
    task :test => :config do
      sh 'RACK_ENV=test bundle exec shoryuken -r ./workers/git_clone_worker.rb -C ./workers/shoryuken_test.yml'
    end

    desc 'Run the background cloning worker in production mode'
    task :production => :config do
      sh 'RACK_ENV=production bundle exec shoryuken -r ./workers/git_clone_worker.rb -C ./workers/shoryuken.yml'
    end
  end
end

desc 'Run application console (irb)'
task :console do
  sh 'irb -r ./init'
end

namespace :vcr do
  desc 'delete cassette fixtures'
  task :wipe do
    sh 'rm spec/fixtures/cassettes/*.yml' do |ok, _|
      puts(ok ? 'Cassettes deleted' : 'No cassettes found')
    end
  end
end

namespace :quality do
  CODE = 'app'

  desc 'run all quality checks'
  task :all => [:rubocop, :reek, :flog]

  task :rubocop do
    sh 'rubocop'
  end

  task :reek do
    sh "reek #{CODE}"
  end

  task :flog do
    sh "flog #{CODE}"
  end
end
