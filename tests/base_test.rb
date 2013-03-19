require 'open-uri'
require 'yaml'
require 'active_support'
require 'active_support/core_ext'
require 'test/unit'
require 'moped'
require 'uber_config'

class BaseTest < ActiveSupport::TestCase

  def terminate_all_servers(sd)
    sd.servers_list.each do |server|
      assert sd.terminate_server(server["id"]), "Can't terminate server"
    end
  end

  def launch_server(sd)
    puts "Trying to launch server"
    sid = sd.launch_server
    puts sid.inspect
    assert sid
    assert sid["id"]
    puts "Server launched:#{sid["id"]}"
    assert sd.wait_until_complete_or_terminate(sid["id"]), "Can't launch server"
    puts "Server finally launched and configured"
    sd.get_server_info(sid["id"])
  end
end
