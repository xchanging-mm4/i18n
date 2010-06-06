require 'bob'
require 'json'

Bob::Builder.class_eval do
  def completed(status, output)
    [status, output] # let's return the actual result, eh?
  end
end

Bob::SCM::Abstract.class_eval do
  def dir_for(commit)
    Bob.directory.join(path) # don't use separate directories per commit
  end
end

module Travis
  class Runner
    attr_reader :env
    
    def call(env)
      @env = env
      status, output = Bob::Builder.new(payload).build
      body = { :status => status, :output => output, :commit => payload['commit'] }.to_json
      # what's an appropriate http status to signal a test failure?
      Rack::Response.new(body, status ? 200 : 400).finish
    rescue JSON::JSONError
      Rack::Response.new("Unparsable payload", 400).finish
    end
    
    protected
    
      def payload
        payload = JSON.parse(Rack::Request.new(env).POST["payload"] || '')
        payload.merge('command' => 'ruby test/backend/simple_test.rb')
      end
  end
end