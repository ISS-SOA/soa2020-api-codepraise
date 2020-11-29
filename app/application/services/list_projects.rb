# frozen_string_literal: true

require 'dry/transaction'

module CodePraise
  module Service
    # Retrieves array of all listed project entities
    class ListProjects
      include Dry::Transaction

      step :validate_list
      step :retrieve_projects

      private

      DB_ERR = 'Cannot access database'

      # Expects list of movies in input[:list_request]
      def validate_list(input)
        list_request = input[:list_request].call
        if list_request.success?
          Success(input.merge(list: list_request.value!))
        else
          Failure(list_request.failure)
        end
      end

      def retrieve_projects(input)
        Repository::For.klass(Entity::Project).find_full_names(input[:list])
          .then { |projects| Response::ProjectsList.new(projects) }
          .then { |list| Success(Response::ApiResult.new(status: :ok, message: list)) }
      rescue StandardError
        Failure(
          Response::ApiResult.new(status: :internal_error, message: DB_ERR)
        )
      end
    end
  end
end
