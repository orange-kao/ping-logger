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
require File.join($EXECUTABLE_PATH, "lib", "StatGenerator.rb")

########################################
# Loading config
########################################

config = IniFile.load(File.join($EXECUTABLE_PATH, "config.ini"))

########################################
# Prepare for the directory
########################################

csv_dir = config["logging"]["csv_dir"]
if csv_dir == nil
  csv_dir = $EXECUTABLE_PATH
end
if Dir.exist?(csv_dir) != true
  FileUtils.mkdir_p(csv_dir)
end

########################################
# CSV generation
########################################

tts = TimeToString.new
db = PingDb.new(config["logging"]["database_file"], false)

csv_file = nil
csv_date = nil
stat_gen = nil

$stdout.puts "This script will read database and generate CSV files"

db.read_result(){|row|
  start_time, rtt_ms, hostname, exception = row

  date_str = start_time.strftime("%F")
  time_str = tts.gen_time_string(start_time)

  if csv_file != nil && csv_date != date_str
    # Date mismatch, close the file
    csv_file.close
    csv_file = nil
    csv_date = nil

    filename = File.join(csv_dir, "#{date_str}_log.csv")
    stat_gen.write_stat_to_file()
    stat_gen = nil
  end

  # Open the file. (overwrite mode)
  if csv_file == nil

    # Open CSV file (overwrite mode)
    filename = File.join(csv_dir, "#{date_str}_log.csv")
    csv_file = CSV.open(filename, "w:utf-8")
    csv_date = date_str
    $stdout.puts "Writing to file #{File.basename(filename)}"
    csv_file << ["Time", "Got respond", "Round trip time (ms)", "Hostname", "Exception"]

    filename = File.join(csv_dir, "#{date_str}_stat.csv")
    stat_gen = StatGenerator.new(filename)
  end

  got_respond = false
  if rtt_ms != nil
    got_respond = true
  end

  csv_row_arr = [time_str, got_respond, rtt_ms, hostname, exception]
  csv_file << csv_row_arr
  stat_gen.add_entry(start_time, rtt_ms, hostname, exception)
}

if csv_file != nil
  csv_file.close
  csv_file = nil
  csv_date = nil
  stat_gen.write_stat_to_file()
  stat_gen = nil
end

$stdout.puts "Done. Check directory #{config["logging"]["csv_dir"].inspect} for CSV files."
$stdout.puts "Press Enter to exit"
$stdin.gets

