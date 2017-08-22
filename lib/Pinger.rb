#!/usr/bin/env ruby
# encoding: utf-8

require "net/ping"

class Pinger
  def initialize(host_list, port, timeout, random_host = false)
    @obj_list = []
    host_list.each{|hostname|
      t_hostname = hostname
      t_port = port
      if hostname.index(":") != nil
        t_hostname, t_port = hostname.split(":")
        t_port = t_port.to_i
      end
      pinger = Net::Ping::TCP.new(t_hostname, t_port, timeout)
      @obj_list.push(pinger)
    }

    @host_current_index = 0
    if random_host == true
      @host_current_index = :random
    end
  end

  def ping
    obj = nil
    if @host_current_index == :random
      obj = @obj_list.sample(1).first
    else
      obj = @obj_list[@host_current_index]
      @host_current_index += 1
      if @host_current_index >= @obj_list.size
        @host_current_index = 0
      end
    end

    ping_result = obj.ping

    # DEBUG ONLY
#    ping_result = nil
#    if Random.rand(10) < 8
#      ping_result = Random.rand(1000) / 1000.0
#    end
    # DEBUG ONLY

    round_trip_time = nil
    if Numeric === ping_result
      round_trip_time = (ping_result * 1000).to_i
    end

    exception = nil
    if obj.exception != nil
      exception = obj.exception.to_s
    end

    return [round_trip_time, obj.host, exception]
  end
end

