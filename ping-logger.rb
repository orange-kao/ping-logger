#!/usr/bin/env ruby
# encoding: utf-8

$INITIAL_PWD = Dir.pwd.dup
$EXECUTABLE_PATH = "#{File.expand_path(File.dirname($PROGRAM_NAME))}"
$stdout.sync = true
$stderr.sync = true

require "time"
require "csv"
require "inifile"
require "fileutils"
require File.join($EXECUTABLE_PATH, "lib", "TimeToString.rb")
require File.join($EXECUTABLE_PATH, "lib", "PingDb.rb")
require File.join($EXECUTABLE_PATH, "lib", "Pinger.rb")

########################################
# Loading config
########################################

config = IniFile.load(File.join($EXECUTABLE_PATH, "config.ini"))

if config["timing"]["second_alignment"] == true && config["timing"]["interval"] < 1
  raise ArgumentError, "Cannot enable the second alignment while interval is less than one second"
end

########################################
# Initialise and start ping loop
########################################

tts = TimeToString.new
pinger = Pinger.new(config["target"]["host"].split(" "), config["target"]["port"], config["timing"]["timeout"], config["target"]["random_host"])
db = PingDb.new(config["logging"]["database_file"], true)

$stdout.puts "This script will ping remost hosts and keep the result in database"
$stdout.puts "To abort, press Ctrl+C"

begin
  while true
    start_time = nil
    if config["timing"]["second_alignment"] == true
      start_time = Time.now.round
    else
      start_time = Time.now
    end

    ping_rtt, ping_hostname, ping_exception = pinger.ping()
    db.add_ping_result(start_time.to_i, ping_rtt, ping_hostname, ping_exception)

    time_str = tts.gen_time_string(start_time)
    ping_is_success = false
    if Numeric === ping_rtt
      ping_is_success = true
    end

    row = [time_str, ping_is_success, ping_rtt, ping_hostname, ping_exception]

    $stdout.puts row.join(" ")

    target_time = start_time + config["timing"]["interval"]
    sleep_time = target_time - Time.now
    if sleep_time > 0
      sleep(sleep_time)
    end
  end
rescue Interrupt => e
  # Ctrl+C
ensure
  db.close
end

