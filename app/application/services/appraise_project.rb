# frozen_string_literal: true

require 'dry/transaction'

module CodePraise
  module Service
    # Analyzes contributions to a project
    class AppraiseProject
      include Dry::Transaction

      step :find_project_details
      step :check_project_eligibility
      step :request_cloning_worker
      step :appraise_contributions

      private

      NO_PROJ_ERR = 'Project not found'
      DB_ERR = 'Having trouble accessing the database'
      CLONE_ERR = 'Could not clone this project'
      NO_FOLDER_ERR = 'Could not find that folder'
      SIZE_ERR = 'Project too large to analyze'

      # input hash keys required: :project, :requested, :config
      def find_project_details(input)
        input[:project] = Repository::For.klass(Entity::Project).find_full_name(
          input[:requested].owner_name, input[:requested].project_name
        )

        if input[:project]
          Success(input)
        else
          Failure(Response::ApiResult.new(status: :not_found, message: NO_PROJ_ERR))
        end
      rescue StandardError
        Failure(Response::ApiResult.new(status: :internal_error, message: DB_ERR))
      end

      def check_project_eligibility(input)
        if input[:project].too_large?
          Failure(Response::ApiResult.new(status: :bad_request, message: SIZE_ERR))
        else
          input[:gitrepo] = GitRepo.new(input[:project], input[:config])
          Success(input)
        end
      end

      def request_cloning_worker(input)
        return Success(input) if input[:gitrepo].exists_locally?

        # Messaging::Queue.new(App.config.CLONE_QUEUE_URL, App.config)
        #   .send(clone_request_json(input))
        notify_clone_workers(input)

        Failure(Response::ApiResult.new(
                  status: :processing,
                  message: { request_id: input[:request_id] }
                ))
      rescue StandardError => e
        print_error(e)
        Failure(Response::ApiResult.new(status: :internal_error, message: CLONE_ERR))
      end

      def appraise_contributions(input)
        input[:folder] = Mapper::Contributions
          .new(input[:gitrepo]).for_folder(input[:requested].folder_name)

        Response::ProjectFolderContributions.new(input[:project], input[:folder])
          .then do |appraisal|
            Success(Response::ApiResult.new(status: :ok, message: appraisal))
          end
      rescue StandardError
        Failure(Response::ApiResult.new(status: :not_found, message: NO_FOLDER_ERR))
      end

      # Helper methods for steps

      def print_error(error)
        puts [error.inspect, error.backtrace].flatten.join("\n")
      end

      def clone_request_json(input)
        Response::CloneRequest.new(input[:project], input[:request_id])
          .then { Representer::CloneRequest.new(_1) }
          .then(&:to_json)
      end

      def notify_clone_workers(input)
        queues = [App.config.CLONE_QUEUE_URL, App.config.REPORT_QUEUE_URL]

        queues.each do |queue_url|
          Concurrent::Promise.execute do
            Messaging::Queue.new(queue_url, App.config)
              .send(clone_request_json(input))
          end
        end
      end
    end
  end
end
