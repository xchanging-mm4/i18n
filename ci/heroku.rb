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

    def server(name, stack = '187')
      new('server', name, stack).setup
    end

    def client(name, stack = '187')
      new('client', name, stack).setup
    end

    def apps
      @apps ||= `heroku list`.split("\n").map { |name| name.split(/\s/).first }
    end
    
    def client_urls
      names = Heroku.apps.select { |name| name =~ /ci-.*-client-/ }
      names.map do |name| "http://#{name}.heroku.com" }
    end
  end

  attr_reader :type, :name, :version

  def initialize(type, name, version)
    @type, @name, @version = type, name, version
  end

  def setup
    create_app unless app_exists?
    add_remote unless remote_exists?
    prepare
    push
    reset
  end

  def app
    "ci-#{name}" + (type == 'client' ? "-#{type}-#{version}" : '' )
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
    `heroku create #{app} --stack #{STACKS[version]}`
  end

  def add_remote
    puts "adding git remote"
    `git remote add #{app} git@heroku.com:#{app}.git`
  end

  def prepare
    `cp ci/#{type}.ru config.ru`
    `cp ci/Gemfile Gemfile`
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