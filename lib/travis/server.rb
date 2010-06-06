require 'sinatra'
require 'cgi'
require 'json'

module Travis
  class Server < Sinatra::Application
    class << self
      def parse_payload(payload)
        map_from_github(JSON.parse(payload))
      end

      # thanks, Bobette
      def map_from_github(payload)
        payload.delete('before')
        payload.delete('commits')
        payload['scm']    = 'git'
        payload['uri']    = git_uri(payload.delete('repository'))
        payload['branch'] = payload.delete('ref').split('/').last
        payload['commit'] = payload.delete('after')
        payload
      end

      def git_uri(repository)
        URI(repository['url']).tap { |u| u.scheme = 'git' }.to_s
      end
    end
    
    attr_reader :name, :url

    def initialize(name, url)
      @name = name
      @url  = url
      super()
    end

    set :views, File.expand_path('../views', __FILE__)

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
        payload = self.class.parse_payload(params[:payload])
        Heroku.runner_urls(name).inject({}) do |result, runner|
          result.merge(runner => build_remote(runner, payload))
        end
      end

      def build_remote(runner, payload)
        # should probably spawn a process per runner here
        build = `curl -sd payload=#{CGI.escape(payload.to_json)} #{runner} 2>&1`
        finished(runner, build)
      end

      def finished(runner, build)
        attributes = JSON.parse(build).merge(:runner => runner, :created_at => Time.now)
        Build.new(attributes).save
        attributes
      end
  end
end