#!/opt/rightscale/sandbox/bin/ruby
#
# Cookbook Name:: snapshot_timer
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


# Arguments: hostname/UUID, unique ID required by RightScale sketchy servers
#            interval, how often to update the RRD
#            lineage, which lineage to monitor

require 'rubygems'
require 'benchmark'
require 'rightscale_tools'
require 'getoptlong'

def usage
  puts "#{$0} -h <hostname> -l <lineage> [-i <sample_interval>]"
  puts "    -h: The hostname of the machine. UUID for RightLink enabled Servers"
  puts "    -l: The block storage lineage to monitor"
  puts "    -i: The sample interval of the file check (in seconds). Default: 1800 seconds"
  exit
end

opts = GetoptLong.new(
  ['--hostname', '-h', GetoptLong::REQUIRED_ARGUMENT],
  ['--lineage', '-l', GetoptLong::REQUIRED_ARGUMENT],
  ['--interval', '-i', GetoptLong::OPTIONAL_ARGUMENT]
)

# Default values.
hostname, lineage, interval = nil, nil, 1800

opts.each do |opt, arg|
  case opt
  when '--hostname'
    hostname = arg
  when '--interval'
    interval = arg.to_i
  when '--lineage'
    lineage = arg
  end
  arg.inspect
end

# Ensure we have all the needed params to run, show usage if we don't.
usage unless lineage && hostname

# Patch find_latest_ebs_backup to increase the timeout
module RightScale
  module Tools
    module API
      class Client10
        def find_latest_ebs_backup(lineage, from_master = nil, timestamp = nil)
          Timeout::timeout(120) do
            seconds = 0
            while true
              begin
                params = {:lineage => lineage}.merge @params
                params[:from_master] = from_master if from_master
                params[:timestamp] = timestamp if timestamp
    @logger.info "Making a RightScale API call to find the latest ebs backup lineage = '#{lineage}', from_master = '#{from_master}', timestamp = '#{timestamp}'"
                request_uri = @url + "/find_latest_ebs_backup.js" + "?" + requestify(params)
                body = RestClient.get(request_uri)
                json = body.nil? ? nil : JSON.load(body)
                break json
              rescue RestClient::Exception => e
                if e.http_code == 422
                  seconds += 10
                  @logger.info "CAUGHT EXCEPTION in find_latest_ebs_backup. #{e}, retrying in #{seconds} seconds"
                  sleep(seconds)
                else
                  raise e
                end
              rescue Exception => e
                raise e
              end
            end
          end
        rescue Exception => e
          display_exception(e, "find_latest_ebs_backup(#{lineage}, #{from_master}, #{timestamp})")
          raise
        end
      end
    end
  end
end

# Main loop
loop do
  api = RightScale::Tools::API.factory('1.0')
  api.logger.level = 2
  RestClient.log = nil
  response_time = Benchmark.realtime { api.find_latest_ebs_backup(lineage)}.to_i
  print "PUTVAL #{hostname}/snapshot_timer-#{lineage}/gauge-age interval=#{interval} #{Time.now.to_i}:#{response_time}\n"
  STDOUT.flush
  sleep interval
end
