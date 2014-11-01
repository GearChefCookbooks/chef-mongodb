#
# Cookbook Name:: mongodb
# Recipe:: replicaset
#
# Copyright 2014, Gary Leong
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

unless node['mongodb']['is_shard']

  Chef::Log.info "Configuring replicaset with mongo nodes specified in yml file ..."

  #Making a libary call to read yml file and see if there are any members
  replicaset,replica_name,members = Chef::ResourceDefinitionList::ReplicaHelper.replicaset_members(node)

  Chef::Log.info "Replicaset is #{replicaset} ... "
  Chef::Log.info "Replica name is #{replica_name} ... "
  Chef::Log.info "Replica members are #{members} ... "

  if replicaset 

    mongos_replica = []
    id = 0
    members.each do |member|
      id += 1
      fqdn = member["fqdn"]
      hostname = member["hostname"]
      port = member["mongodb"]["config"]["port"] 
      replica_name = member["mongodb"]["replica_name"]
      Chef::Log.info "mongodb replica_name: #{replica_name}, id: #{id}, fqdn: #{fqdn}, port: #{port}"

      replica = {}
      replica[:ip]   = fqdn
      replica[:port] = port
      replica[:id]   = id
      mongos_replica << replica
 
    end

    template "/tmp/mongo_replicaset.js" do
      source "mongo_replicaset.erb"
      mode 0644
      owner "root"
      group "root"
      variables(
        :mongos_replica => mongos_replica,
        :replica_name   => replica_name
      )
    end

    execute "initiate replication" do
      command "cat /tmp/mongo_replicaset.js | /usr/bin/mongo localhost:27017"
      #not_if "echo 'rs.status()' | mongo local | grep -q 'run rs.initiate'"
      not_if "echo 'rs.status()' | mongo local | grep 'PRIMARY|SECONDARY'"
    end

  else

     Chef::Log.warn "***********************************"
     Chef::Log.warn "No nodes found for a replica set ..."
     Chef::Log.warn "File exit status set at 185 ..."
     Chef::Log.warn "***********************************"

     file "/tmp/file_exit_status" do
       content "185"
       owner 'root'
       group 'root'
       mode '444'
     end

  end

end


