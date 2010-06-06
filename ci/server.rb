require 'cgi'
require 'json'

module Ci
  class Server < Sinatra::Application
    attr_reader :repository, :clients

    def initialize(repository)
      @repository = repository
      @clients    = Heroku.client_urls
      super()
    end

    set :views, File.expand_path('../../views', __FILE__)

    get '/' do
      @builds = Build.all
      erb :builds
    end

    post '/' do
      result = build_all
      Rack::Response.new(result.to_json, 200).finish
    end

    protected

      def build_all
        payload = map_from_github(params[:payload])
        clients.inject({}) do |result, client|
          result.merge(client => build_remote(client, payload))
        end
      end

      def build_remote(client, payload)
        # should probably spawn a process per client here
        build = `curl -sd payload=#{CGI.escape(payload.to_json)} #{client} 2>&1`
        finished(client, build)
        build
      end

      def finished(client, build)
        attributes = JSON.parse(build).merge(:client => client, :created_at => Time.now)
        Build.new(attributes).save
      end

      # thanks, Bobette
      def map_from_github(payload)
        payload = JSON.parse(payload)
        payload.delete("before")
        payload["scm"]    = "git"
        payload["uri"]    = git_uri(payload.delete("repository"))
        payload["branch"] = payload.delete("ref").split("/").last
        payload["commit"] = payload.delete("after")
        payload
      end

      def git_uri(repository)
        URI(repository["url"]).tap { |u| u.scheme = "git" }.to_s
      end
  end
end