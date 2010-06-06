module Travis
  class Heroku
    STACKS = {
      '186' => 'aspen-mri-1.8.6',
      '187' => 'bamboo-ree-1.8.7',
      '191' => 'bamboo-mri-1.9.1'
    }

    class << self
      def each_stack(&block)
        Heroku::STACKS.keys.each(&block)
      end

      def server(name, repository)
        new('server', name, '187', repository).setup
      end

      def runner(name, stack = '187')
        new('runner', name, stack).setup
      end

      def apps
        @apps ||= `heroku list`.split("\n").map { |name| name.split(/\s/).first }
      end
    
      def runner_urls(name)
        STACKS.keys.map { |stack| "http://ci-#{name}-runner-#{stack}.heroku.com" }
      end
    end

    attr_reader :type, :name, :stack, :repository

    def initialize(type, name, stack, repository = '')
      @type       = type
      @name       = name
      @stack      = stack
      @repository = repository
    end

    def setup
      create_app unless app_exists?
      add_remote unless remote_exists?
      set_config
      prepare
      push
      reset
    end

    def app
      "ci-#{name}" + (type == 'runner' ? "-#{type}-#{stack}" : '' )
    end

    def url
      "http://#{app}.heroku.com"
    end

    def app_exists?
      puts "checking for #{app} ..."
      Heroku.apps.include?(app)
    end

    def remote_exists?
      remotes.include?(app)
    end

    def create_app
      puts "creating #{app} ..."
      `heroku create #{app} --stack #{STACKS[stack]}`
    end

    def add_remote
      puts "adding git remote"
      `git remote add #{app} git@heroku.com:#{app}.git`
    end
    
    def set_config
      `heroku config:add TRAVIS_NAME=#{name} TRAVIS_URL=#{repository} --app #{app}`
    end

    def prepare
      dir = File.expand_path('..', __FILE__)
      `cp #{dir}/#{type}.ru config.ru`
      `cp #{dir}/Gemfile Gemfile`
      `git add config.ru Gemfile`
      `git commit -m 'ci #{type}'`
    end

    def push
      puts "pushing to #{app} ..."
      `git push #{app} ci:master --force`
    end

    def reset
      `rm -f Gemfile config.ru > /dev/null`
      `git reset ci^`
    end

    def remotes
      @remotes ||= `git remote`.split("\n")
    end
  end
end