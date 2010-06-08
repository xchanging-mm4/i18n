require 'thor'

module Travis
  class Tasks < Thor
    namespace :travis
    
    desc "setup [name]", "Scaffold Travis setup."
    method_options :name => :optional # the library name

    def setup
      name = options['name'] || File.basename(Dir.pwd)
      Travis.scaffold(name)
    end
    
    desc "install", "Install/update your Travis setup to heroku."
    def install
      Travis.install
    end
    
    protected
    
      def options
        Hash[super.to_a] # i can haz hash
      end
  end
end