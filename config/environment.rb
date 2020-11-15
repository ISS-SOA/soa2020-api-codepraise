# frozen_string_literal: true

require 'roda'
require 'econfig'
require 'delegate'

module CodePraise
  # Environment-specific configuration
  class App < Roda
    plugin :environments

    extend Econfig::Shortcut
    Econfig.env = environment.to_s
    Econfig.root = '.'

    use Rack::Session::Cookie, secret: config.SESSION_SECRET

    configure :development, :test do
      ENV['DATABASE_URL'] = "sqlite://#{config.DB_FILENAME}"
    end

    configure :production do
      # Set DATABASE_URL environment variable on production platform
    end

    configure do
      require 'sequel'
      DB = Sequel.connect(ENV['DATABASE_URL']) # rubocop:disable Lint/ConstantDefinitionInBlock

      def self.DB # rubocop:disable Naming/MethodName
        DB
      end
    end
  end
end
