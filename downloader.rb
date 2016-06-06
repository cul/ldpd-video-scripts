#!/usr/bin/env ruby
$:.unshift File.expand_path("../lib", __FILE__)
################################################################################
# downloader.rb
# batch rsync video from batchmakerpro batch file
# usage: ruby downloader.rb [-FLAGS] CSV_FILE SOURCE_ROOT DESTINATION_ROOT
################################################################################
# TODO:
# - show how long each job takes
###

require 'rubygems'
require 'bundler/setup'
Bundler.require
require 'csv'

puts <<BM
 _____________
< downloader >
 -------------
BM

def help(msg = nil)
  puts "ruby rsync.rb [-FLAGS] CSV_FILE HOST SYNCH_ROOT"
  puts msg if msg
  exit
end

has_flags = (ARGV[0] =~ /^-[a-zA-Z0-9]+$/)

csv_ix = 0
host_ix = 1
synch_ix = 2

if has_flags
    csv_ix += 1
    host_ix += 1
    synch_ix += 1
end

help unless ARGV[0]
help if has_flags && ARGV[0] =~ /h/

is_verbose = has_flags && ARGV[0] =~ /v/

# rsync flags we want
## -a preserves modification time, access time, permissions, etc.
## -vhP print human-friendly messages to console
rsync_flags = is_verbose ? "-avhP" : "-a"

batchfile = ARGV[csv_ix] || "./batchfile.csv"

help("CSV_FILE \"#{batchfile}\" does not exist") unless File.exist?(batchfile)
synch_root = ARGV[synch_ix] || File.join("/", "Volumes","vid1")
help("SYNCH_ROOT value of \"#{synch_root}\" does not exist") unless File.exist?(synch_root)

host = ARGV[host_ix]

CSV.open(batchfile, "rb", headers: true) do |csv|
  csv.each do |row|
    next if row.header_row?
    file_name = row[0]
    remote_dir_path = row[1]
    synch_dir_path = remote_dir_path =~ /^\// ? remote_dir_path[1..-1] : remote_dir_path 
    video_source_path =  File.join(remote_dir_path, file_name)
    video_synch_path = File.join(synch_root, synch_dir_path, file_name)
    cmd = ["rsync", rsync_flags, "#{host}:#{video_source_path}", video_synch_path]

    begin
      cmd_out = ''
      IO.popen(cmd, 'r') { |cmd_io| cmd_out = cmd_io.read }
      unless $? == 0
        puts cmd_out
        raise "unexpected exit status #{$?}"
      end
    rescue StandardError => e
      puts "Failure on: \"#{cmd}\""
      puts "\t#{e.message}"
    end
  end
end