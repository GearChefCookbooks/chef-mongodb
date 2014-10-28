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

#include_recipe "mongodb"
include_recipe "mongodb::mongo_gem"

service node[:mongodb][:init_service_name] do
  supports :restart => true, :reload => true
  action [:enable, :start]
end

#Reboot server once after mongo replica setup
#This was needed for lxc vms
bash "reboot_once" do
  user "root"
  code <<-EOH
    echo "#!/bin/bash" > /var/tmp/reboot_once.sh 
    echo "rm -rf /etc/cron.d/reboot_once" >> /var/tmp/reboot_once.sh
    echo "/sbin/reboot" >> /var/tmp/reboot_once.sh
    chmod 700 /var/tmp/reboot_once.sh

    echo "*/3 * * * * root /var/tmp/reboot_once.sh" > /etc/cron.d/reboot_once
    service cron restart
  EOH
  action :nothing
  not_if {File.exists?("/var/tmp/reboot_once.sh")}
end

unless node['mongodb']['is_shard']

  Chef::Log.info "Configuring replicaset with mongo nodes specified in yml file ..."

  #Making a libary call to read yml file and see if there are any members
  replicaset,replica_name,members = Chef::ResourceDefinitionList::ReplicaHelper.replicaset_members(node)

  Chef::Log.info "Replicaset is #{replicaset} ... "
  Chef::Log.info "Replica name is #{replica_name} ... "
  Chef::Log.info "Replica members are #{members} ... "

  if replicaset 

      #Chef::Log.info "mongod.conf changed for: #{node["hostname"]} == #{hostname}"
      template node[:mongodb][:dbconfig_file] do
        source "mongodb.simple.repl.conf.erb"
        mode 0644
        owner "root"
        group "root"
        variables(
          :replica_name => replica_name
        )
        notifies :restart, "service[#{node[:mongodb][:init_service_name]}]"
        notifies :run, "bash[reboot_once]"
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


