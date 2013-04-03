require 'active_support/core_ext'
require 'aws'
require 'appoxy_api'

#workaround for timeouts, should be implemented in appoxy_api gem
module RestClient
  class Request
    def self.execute(args, & block)
      puts "Execute called with following arguments:#{args.inspect}"
      args.merge!({:timeout => 600, :open_timeout => 600})
      new(args).execute(& block)
    end
  end
end


class SDService < Appoxy::Api::Client
  attr_accessor :project_id

  def initialize(access_key, secret_key,options={})
    super(options[:host] || "http://www.simpledeployer.com/api/", access_key, secret_key)
    #puts "SD #{access_key}, #{secret_key}"
    self.version = "0.3"
  end

  def projects()
    get("projects")
  end

  def project_info(project_id=nil)
    get("projects/#{project_id || self.project_id}")
  end

  def servers_list(project_id=nil)
    get("projects/#{project_id || self.project_id}/servers")
  end

  def get_server_info(server_id)
    get("servers/#{server_id}/")
  end

  def exec_command(server_id, command)
    begin
      res = post("servers/#{server_id}/shell", exec: command)
      res['res']
    rescue => ex
      puts "Error in exec:#{ex.inspect}"
    end
  end

  def create_project(params)
    begin
      res = post("projects", params)
      res['id']
    rescue => ex
      puts "Error in exec:#{ex.inspect}"
    end
  end

  def delete_project(project_id=nil)
    delete("projects/#{project_id || self.project_id}")
  end

  def launch_server(params={})
    data = {"launch_in_worker"=>"true", "branch"=>"master"}
    get("projects/#{project_id}/launch_server", data.merge(params))
  end

  def wait_until_complete_or_terminate(server_id)
    x = 0
    details = {}
    server_status = %w'not started terminated'
    launch_status = %w'error complete cancelled'
    while x < 300
      details = get_server_info(server_id)
      puts "Details:#{details['launch_status']}" if details['launch_status']
      break if details && details['status']&& details['launch_status'] &&
          (server_status.include?(details['status']) || launch_status.include?(details['launch_status']['status']))
      sleep 5
      x+=1
    end
    #server won't run, killing it
    if x >= 200 || details['launch_status']['status'] != 'complete'
      puts "terminating server"
      terminate_server(server_id)
    end
    details['launch_status']['status'] == 'complete'
  end


  # options can include:
  # :silent => true/false. If true, no notifications will be sent.
  def terminate_server(server_id, options={})
    # appoxy_api doesn't like symbols
    delete("servers/#{server_id}", stringify(options))
  end

  def stringify(hash)
    new_hash = {}
    hash.each_pair do |key, value|
      new_hash[key.to_s] = value.to_s
    end
    new_hash
  end

  def get_servers_list(domain)
    list = self.servers_list().collect { |s| s["status"]=="running" ? s[domain] : nil }
    list.compact!
    list
  end

  def get_domains_list()
    get_servers_list("url")
  end

  def get_servers_id_list()
    get_servers_list("id")
  end

  def process_servers(counter)
    if counter > 0
      (counter).times do
        launch_server() rescue "Launched" #TODO fix non jsoned message from sd API
      end
    elsif counter<0
      counter = counter.abs #make positive!
      ids = get_servers_id_list()
      if ids.size > 0
        counter.times do |i|
          terminate_server(ids[ids.size-i])
        end
      end
    else
      puts "nothing to do"
    end
  end

end
