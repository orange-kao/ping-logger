#!/usr/bin/env ruby
# encoding: utf-8

class TimeToString
  def is_dst_date(t)
    if @t_start_i != nil && @t_end_i != nil && t.to_i >= @t_start_i && t.to_i < @t_end_i
      return @dst_stat
    end

    t_start = Time.parse("#{t.strftime("%F")}T00:00:00")
    t_end   = Time.parse("#{t.strftime("%F")}T24:00:00")

    @t_start_i = t_start.to_i
    @t_end_i = t_end.to_i
    if t_start.isdst == false && t_end.isdst == false
      @dst_stat = false
    else
      @dst_stat = true
    end
    return @dst_stat
  end

  def gen_time_string(t)
    if is_dst_date(t) == false
      return t.strftime("%T")
    end
    return t.strftime("%T%:z")
  end
end

#p = nil
#tts = TimeToString.new
#ref_time = Time.now
#(0..(2*60*60*24*365*10)).each{|i|
#  now = ref_time + (0.5 * i)
#  r = tts.is_dst_date(now)
#  if p == nil
#    p = r
#  end
#  if p != r
#    puts "#{now.strftime("%F")} #{r}"
#    p = r
#  end
#}
#exit

