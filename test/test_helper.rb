$: << File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'test/unit'
require 'rack/test'
require 'test_declarative'
require 'database_cleaner'
require 'mocha'

require 'pp'
require 'cgi'
require 'json'

require 'bob'
require 'travis'
require 'travis/build'
require 'mocha'

DataMapper.setup(:default, "sqlite3:///tmp/travis-test.db")
DataMapper.auto_upgrade!

DatabaseCleaner.strategy = :truncation

# module Kernel
#   def `(cmd)
#     system(cmd)
#   end
# 
#   def system(cmd)
#     # TODO should rather expect these individually per test. or use a better mocking lib.
#     cmds = {
#       'curl -sd payload=' => '{"status": true, "output": "output"}',
#       'git fetch origin' => true,
#       'git checkout origin/master' => true,
#       'git reset --hard' => true,
#       'git show -s' => "---\nid: 25456ac13e5995b4a4f68dcf13d5ce95b1a687a7\nauthor: Sven Fuchs <svenfuchs@artweb-design.de>\nmessage: >-\n  don't run gettext/backend tests on 1.9.1p129\ntimestamp: 2010-06-06 03:04:26 +0200"
#     }
#     cmds.each { |key, value| return value if cmd.include?(key) }
#     raise "cmd stub not found for #{cmd}"
#   end
# end

require 'stringio'
 
module Kernel
  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out
  ensure
    $stdout = STDOUT
  end
end

class Test::Unit::TestCase
  def teardown
    DatabaseCleaner.clean
  end
end
