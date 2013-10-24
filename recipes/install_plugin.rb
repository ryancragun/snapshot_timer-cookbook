#
# Cookbook Name:: snapshot_timer
# Recipe:: install_plugin
#
# Copyright (C) 2013 Ryan Cragun
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

rightscale_marker

return unless node[:snapshot_timer][:enable_plugin] == "true"

rightscale_enable_collectd_plugin "exec"
include_recipe "rightscale::default"
include_recipe "rightscale::install_tools"

require 'fileutils'

log "   Installing snapshot_timer collectd plugin.."

template(::File.join(node[:rightscale][:collectd_plugin_dir], "snapshot_timer.conf")) do
  backup false
  source "snapshot_timer.conf.erb"
  notifies :restart, resources(:service => "collectd")
  variables(
    :collectd_lib => node[:rightscale][:collectd_lib],
    :instance_uuid => node[:rightscale][:instance_uuid],
    :lineage => node[:snapshot_timer][:lineage],
    :interval => node[:snapshot_timer][:interval]
  )
end

directory ::File.join(node[:rightscale][:collectd_lib], "plugins") do
  action :create
  recursive true
end

cookbook_file(::File.join(node[:rightscale][:collectd_lib], "plugins", 'snapshot_timer.rb')) do
  source "snapshot_timer.rb"
  mode "0755"
  notifies :restart, resources(:service => "collectd")
end

file "/var/spool/cloud/user-data.rb" do
  owner "root"
  group "root"
  mode "0664"
  action :touch
end

log "   Installed collectd snapshot_timer plugin."
