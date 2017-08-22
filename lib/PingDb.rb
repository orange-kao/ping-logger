#!/usr/bin/env ruby
# encoding: utf-8

require "sqlite3"

class PingDb
  def initialize(filename, allow_create_file = false)
    is_exist = File.exist?(filename)

    if allow_create_file == false && is_exist == false
      raise RuntimeError, "Database not exist"
    end

    @db = SQLite3::Database.new(filename)
    @db.busy_timeout = 60000
    @db.execute "pragma foreign_keys = on;"

    @db.execute "begin transaction;"
    @db.execute <<-SQL
      create table if not exists host (
        id integer primary key,
        hostname text not null,
        unique (hostname)
      );
    SQL
    @db.execute <<-SQL
      create table if not exists exception (
        id integer primary key,
        message text not null,
        unique (message)
      );
    SQL
    @db.execute <<-SQL
      create table if not exists result (
        id integer primary key,
        start_time integer not null,
        rtt_ms integer,
        host_id references host(id) not null,
        exception_id references exception(id)
      );
    SQL
    @db.execute "commit;"
  end

  def close
    @db.close
    @db = nil
    return
  end

  def add_ping_result(start_time, rtt_ms, hostname, exception = nil)
    host_id = add_host(hostname)
    exception_id = add_exception(exception)
    @db.execute("insert into result (start_time, rtt_ms, host_id, exception_id) values (?, ?, ?, ?);", [start_time, rtt_ms, host_id, exception_id])
    return
  end

  def read_result
    sql = <<-SQL
      select result.start_time, result.rtt_ms, host.hostname, exception.message
        from result
        join host on host.id = result.host_id
        left join exception on exception.id = result.exception_id
        order by result.start_time asc;
    SQL

    if block_given? == false
      rows = @db.execute(sql)
      return rows
    end

    @db.execute(sql){|row|
      time = Time.at(row[0])
      yield [time, row[1], row[2], row[3]]
    }
    return
  end

  private
  def add_host(str)
    return add_something("host", "hostname", str)
  end

  def add_exception(str)
    return add_something("exception", "message", str)
  end

  def add_something(table, field, data)
    if data == nil
      return nil
    end

    row_id = @db.execute("select id from #{table} where #{field}=?;", [data])
    if row_id.size != 0
      return row_id[0][0]
    end

    @db.execute("insert into #{table} (#{field}) values (?);", [data])
    row_id = @db.execute("select last_insert_rowid();")
    return row_id[0][0]
  end
end

