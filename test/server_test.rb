require File.expand_path('../test_helper', __FILE__)

class ServerTest < Test::Unit::TestCase
  include Rack::Test::Methods

  PAYLOAD = {
    'before'     => '533373f50625df607c9fed0092581b75abffb183',
    'repository' => { 'url' => 'http://github.com/svenfuchs/i18n', 'name' => 'i18n' },
    'commits'    => [{ 'id' => '25456ac13e5995b4a4f68dcf13d5ce95b1a687a7' }],
    'after'      => '25456ac13e5995b4a4f68dcf13d5ce95b1a687a7',
    'ref'        => 'refs/heads/master'
  }
  
  def app
    Travis::Server.new('i18n', 'http://github.com/svenfuchs/i18n')
  end
  
  def setup
    super
    Travis::Build.create(
      :runner     => 'ci-i18n-client-191',
      :commit     => '25456ac13e5995b4a4f68dcf13d5ce95b1a687a7',
      :status     => true,
      :output     => 'build output',
      :created_at => Time.now
    )
  end
  
  def teardown
    super
    DatabaseCleaner.clean
  end

  test 'can render' do
    get '/'
    assert last_response.ok?
  end

  test 'can build' do
    post '/', :payload => PAYLOAD.to_json
    assert last_response.ok?
    result = JSON.parse(last_response.body)
    assert_equal true, result['http://ci-i18n-runner-191.heroku.com']['status']
  end
  
  test 'map_from_github' do
    expected = {
      'scm'     => 'git',
      'uri'     => 'git://github.com/svenfuchs/i18n',
      'branch'  => 'master',
      'commit'  => '25456ac13e5995b4a4f68dcf13d5ce95b1a687a7'
    }
    assert_equal expected, Travis::Server.map_from_github(PAYLOAD)
  end
end