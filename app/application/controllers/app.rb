# frozen_string_literal: true

require 'roda'
require_relative 'lib/init'

module CodePraise
  # Web App
  class App < Roda
    plugin :halt
    plugin :all_verbs # allows DELETE and other HTTP verbs beyond GET/POST
    plugin :caching
    use Rack::MethodOverride # for other HTTP verbs (with plugin all_verbs)

    route do |routing|
      response['Content-Type'] = 'application/json'

      # GET /
      routing.root do
        message = "CodePraise API v1 at /api/v1/ in #{App.environment} mode"

        result_response = Representer::HttpResponse.new(
          Response::ApiResult.new(status: :ok, message: message)
        )

        response.status = result_response.http_status_code
        result_response.to_json
      end

      routing.on 'api/v1' do
        routing.on 'projects' do
          routing.on String, String do |owner_name, project_name|
            # GET /projects/{owner_name}/{project_name}[/folder_namepath/]
            routing.get do
              Cache::Control.new(response).turn_on if Env.new(App).production?

              path_request = Request::ProjectPath.new(
                owner_name, project_name, request
              )

              result = Service::AppraiseProject.new.call(requested: path_request)

              Representer::For.new(result).status_and_body(response)
            end

            # POST /projects/{owner_name}/{project_name}
            routing.post do
              result = Service::AddProject.new.call(
                owner_name: owner_name, project_name: project_name
              )

              Representer::For.new(result).status_and_body(response)
            end
          end

          routing.is do
            # GET /projects?list={base64 json array of project fullnames}
            routing.get do
              list_req = Request::EncodedProjectList.new(routing.params)
              result = Service::ListProjects.new.call(list_request: list_req)

              Representer::For.new(result).status_and_body(response)
            end
          end
        end
      end
    end
  end
end
