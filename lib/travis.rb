module Travis
  autoload :Build,  'travis/build'
  autoload :Runner, 'travis/runner'
  autoload :Heroku, 'travis/heroku'
  autoload :Server, 'travis/server'
  
  class << self
    def setup(name, url)
      Heroku.server(name, url)
      Heroku.each_stack { |stack| Heroku.runner(name, stack) }
    end
  end
end