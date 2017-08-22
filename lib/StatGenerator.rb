#!/usr/bin/env ruby
# encoding: utf-8

class StatGenerator
  def initialize(filename)
    @filename = filename

    @date_arr = []
    @time_first = nil
    @time_last = nil

    @time_previous = nil
    @time_gap_max = 0

    @entry_count = 0
    @got_respond_count = 0
    @rtt_sum = 0

    @success_in_a_row_max = 0
    @success_in_a_row_current = 0

    @fail_in_a_row_max = 0
    @fail_in_a_row_current = 0

    @host_success_arr = []
    @host_fail_arr = []
  end

  def add_entry(time, rtt_ms, hostname, exception)
    got_respond = false
    if rtt_ms != nil
      got_respond = true
    end

    iso_date = time.strftime("%F")
    if @date_arr.include?(iso_date) != true
      @date_arr.push(iso_date)
    end

    if @time_first == nil
      @time_first = time
    end
    @time_last = time

    if @time_previous == nil
      @time_previous = time
    end
    time_gap = time - @time_previous
    if time_gap > @time_gap_max
      @time_gap_max = time_gap
    end
    @time_previous = time

    @entry_count += 1
    if got_respond == true
      @got_respond_count += 1
      @rtt_sum += rtt_ms
    end

    if got_respond == true
      @success_in_a_row_current += 1
      @fail_in_a_row_current = 0
    else
      @success_in_a_row_current = 0
      @fail_in_a_row_current += 1
    end

    if @success_in_a_row_max < @success_in_a_row_current
      @success_in_a_row_max = @success_in_a_row_current
    end
    if @fail_in_a_row_max < @fail_in_a_row_current
      @fail_in_a_row_max = @fail_in_a_row_current
    end

    if got_respond == true
      if @host_success_arr.include?(hostname) != true
        @host_success_arr.push(hostname)
      end
    else
      if @host_fail_arr.include?(hostname) != true
        @host_fail_arr.push(hostname)
      end
    end

    return
  end

  def gen_stat
    result = {}
    tts = TimeToString.new
    result["Date (ISO 8601)"] = @date_arr.join(" ")
    result["Time of first entry"] = tts.gen_time_string(@time_first)
    result["Time of last entry"] = tts.gen_time_string(@time_last)
    result["Largest gap between each entry (seconds)"] = @time_gap_max.round(2)

    result["Number of ping attempt"] = @entry_count
    result["Respond rate"] = "#{(@got_respond_count.to_f / @entry_count * 100).round(2)}%"
    result["Average round trip time (ms)"] = (@rtt_sum.to_f / @got_respond_count).round(2)
    result["Highest ping success in a row"] = @success_in_a_row_max
    result["Highest ping failure in a row"] = @fail_in_a_row_max

    result["The host always respond"] = (@host_success_arr - @host_fail_arr).sort.join(" ")
    result["The host never respond"]  = (@host_fail_arr - @host_success_arr).sort.join(" ")

    return result
  end

  def write_stat_to_file(filename = @filename)
    result = gen_stat()
    CSV.open(filename, "w:utf-8"){|csv|
      csv << ["Key", "Value"]
      result.each{|key, value|
        csv << [key, value]
      }
    }
    return
  end    
end

