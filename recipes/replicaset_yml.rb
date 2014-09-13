#
# Cookbook Name:: mongodb
# Recipe:: replicaset
#
# Copyright 2011, edelight GmbH
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

include_recipe "mongodb"
include_recipe "mongodb::mongo_gem"

#node.set['mongodb']['is_replicaset'] = true
#node.set['mongodb']['cluster_name'] = node['mongodb']['cluster_name']

unless node['mongodb']['is_shard']

  Chef::Log.info "Configuring replicaset with mongo nodes specified in yml file ..."

  #Making a libary call to read yml file and see if there are any members
  replicaset,replica_name,members = Chef::ResourceDefinitionList::ReplicaHelper.replicaset_members(node)

  Chef::Log.info "Node info is #{replicaset} ... "
  Chef::Log.info "Replica name is #{replica_name} ... "
  Chef::Log.info "Replica members are #{members} ... "

  if replicaset
     Chef::ResourceDefinitionList::MongoDB.configure_replicaset(node,replica_name,members)
     execute "sleep 300" do
       command "sleep 300"
       action :run
     end
     Chef::ResourceDefinitionList::MongoDB.configure_replicaset(node,replica_name,members)
  else
     Chef::Log.warn "No nodes found for a replica set ..."
  end

end


