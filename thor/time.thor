#
# Project specific time tracking stuff
#
require 'fileutils';

class Tt < Thor
  include Thor::Actions

  def self.source_root 
    File.dirname(__FILE__)
  end

  desc("add_time", "Add time worked to a project")
  method_option(:file, :default => "time", :type => :string, :aliases => "-f")
  def add_time
    default_date = Time.now.strftime("%d/%m/%y")
    date = ask("Enter the date or hit enter [#{default_date}]:") 
    if(date.nil? || date.empty?)
      date = default_date
    end

    stime = ask("Enter the start time [hh:mm]:")
    stime = ask("No start time entered, try again [hh:mm]") unless stime
    throw("No start time entered, bailing out") unless stime

    end_time = Time.now.strftime("%H:%M")
    etime = ask("Enter the end time or hit enter [#{end_time}]:")
    if(etime.nil? || etime.empty?)
      etime = end_time
    end

    comment = ask("Enter a comment:")

    #puts("File [#{options[:file]}], Date [#{date}], Start [#{stime}], End [#{etime}], Comment [#{comment}]")

    # work out the hours and minutes
    start_list = stime.split(":")
    end_list = etime.split(":")

    puts(" [#{start_list}]") 
    puts(" [#{end_list}]") 

    hours = end_list[0].to_i - start_list[0].to_i
    mins = end_list[1].to_i - start_list[1].to_i
    if(mins < 0)
      hours -= 1
      mins += 60
    end

    if(mins < 10)
      mins = "0#{mins}"
    end

    #puts("File [#{options[:file]}], Date [#{date}], Start [#{stime}], End [#{etime}], Total  [#{hours}:#{mins}] ")

    File.exists?(options[:file]) || File.new(options[:file], File::CREAT)

    append_file(options[:file], "#{date} | #{stime} => #{etime} | #{hours}:#{mins} | #{comment}\n")
  end

  desc("total_time", "Add up the total time that has been worked")
  method_option(:file, :default => "time", :type => :string, :aliases => "-f")
  def total_time
    throw("No file exists at [#{options[:file]}") unless File.exists?(options[:file])
    
    @total_days = 0
    @total_hours = 0
    @total_mins = 0
    @dates = []
    @detail_array = []

    # loop through at the values in our time file and add up the hours
    # totals per day and total in the file
    IO.foreach(options[:file]) do | line | 
      entries = line.split("|")
      #puts(" [#{entries}]")
      entries.each { | entry | entry && entry.strip! }
      #puts(" [#{entries}]")
      @detail_array << entries
      unless(@dates.include?(entries[0]))
        @total_days += 1
        @dates << entries[0]
      end
      hours_mins = entries[2].split(":")
      @total_hours += hours_mins[0].to_i
      @total_mins += hours_mins[1].to_i
    end

    #clean up the hours and minutes
    @total_hours += @total_mins / 60
    @total_mins = @total_mins % 60

    # the last thing that we do is run the template
    template("time.tt", "time.html")
  end
end
