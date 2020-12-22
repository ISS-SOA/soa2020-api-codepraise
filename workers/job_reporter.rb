# frozen_string_literal: true

require_relative 'progress_publisher'

module GitClone
  # Reports job progress to client
  class JobReporter
    attr_accessor :project

    def initialize(request_json, config)
      clone_request = CodePraise::Representer::CloneRequest
        .new(OpenStruct.new)
        .from_json(request_json)

      @project = clone_request.project
      @publisher = ProgressPublisher.new(config, clone_request.id)
    end

    def report(msg)
      @publisher.publish msg
    end

    def report_each_second(seconds, &operation)
      seconds.times do
        sleep(1)
        report(operation.call)
      end
    end
  end
end
