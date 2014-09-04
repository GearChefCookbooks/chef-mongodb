require 'chef/node'
require 'yaml'

class Chef::ResourceDefinitionList::ReplicaHelper

  def self.read_replica_yml(node)
    yaml_file = node["mongodb"]["config"]["replica_file"]
    raw_config = File.read(yaml_file)
    instances = YAML.load(raw_config)
  end

  # create array of node objects for replica set
  def self.replicaset_members(node)

    begin
       instances = self.read_replica_yml(node)
    rescue
       Chef::Log.warn "Cannot retrieve info from #{node["mongodb"]["config"]["replica_file"]}"
       exit 0
    end

    priority = 500
    members = []
    instances.each do |name, instance|
      priority -= 5
      member = Chef::Node.new
      member.name(name)
      member.default['fqdn'] = instance["ipaddresses"]["private"]
      member.default['ipaddress'] = instance["ipaddresses"]["private"]
      member.default['hostname'] = name
      mongodb_attributes = {
        # here we could support a map of instances to custom replicaset options in the custom json
        'port' => node['mongodb']['port'],
        'replica_arbiter_only' => false,
        'replica_build_indexes' => true,
        'replica_hidden' => false,
        'replica_slave_delay' => 0,
        'replica_priority' => priority,
        'replica_tags' => {}, # to_hash is called on this
        'replica_votes' => 1
      }
      member.default['mongodb'] = mongodb_attributes
      members << member
    end

    #We want at least 1 node to create a replicaset or a basis for a replicaset
    members.empty? ? replicaset = false : replicaset = true

    return relicaset,members

  end

end
