require File.expand_path(File.dirname(__FILE__) + '/base_test.rb')

class TestSd < BaseTest

  def setup
    require File.expand_path(File.dirname(__FILE__) + '/../lib/sd_service.rb')
    @config = UberConfig.load
    puts "config=" + @config.inspect
    @sd = SDService.new(@config["sd"]["access_key"], @config["sd"]["secret_key"], host:'http://simpledeployer-staging.irondns.info/api/')
  end

  def test_rails_server
    pid = @config["sd"]["project_id"]
    assert pid
    puts "Project found:#{pid}"
    @sd.project_id = pid
    terminate_all_servers(@sd)
    begin
      info = launch_server(@sd)
      assert info
      sleep 30 # wait until server get ready
      res = open("http://#{info["hostname"]}")
      assert res
      assert_equal res.status[0], "200"
    ensure
      terminate_all_servers(@sd)
    end
  end

  def test_mongo_server
    pid = @config["sd"]["mongo_project_id"]
    assert pid
    puts "Project found:#{pid}"
    @sd.project_id = pid
    terminate_all_servers(@sd)
    begin
      info = launch_server(@sd)
      assert info
      puts "#{info["hostname"]}:27017"
      moped = Moped::Session.new(["#{info["hostname"]}:27017"])
      moped.use(:admin)
      moped.login('user', 'pass')
      assert moped.databases
    ensure
      terminate_all_servers(@sd)
    end
  end

end