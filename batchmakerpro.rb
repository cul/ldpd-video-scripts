#!/usr/bin/env ruby
################################################################################
# batchmakerpro.rb
# video analyzer, prober, and csv batch-list maker
# usage: batchmakerpro.rb [SOURCE_DIR] [CSV_OUTFILE]
################################################################################

require 'rubygems'
require 'bundler/setup'
Bundler.require
require 'csv'

source_dir = ARGV[0] || "."
outfile_path = ARGV[1] || "./batchfile.csv"
exts = "mp4,vob,wmv,avi,mpg,mpeg,asf,mov,3gp,m4v,flv"

puts <<BM
 _______________
< batchmakerpro >
 ---------------
BM

puts "Source dir: "+source_dir
puts "CSV destination path: "+outfile_path
unless outfile_path.end_with?(".csv")
	puts "ERROR: CSV outfile must end with .csv" 
	exit
end

vids = Dir.glob("#{source_dir}/**/*.{#{exts}}", File::FNM_CASEFOLD)
vids_downcase_paths = vids.map{|vid_path| vid_path.downcase}
# raise error if duplicate paths exist
if vids_downcase_paths.length != vids_downcase_paths.uniq.length
	puts "ERROR: Duplicate paths found." 
	exit
end

if vids.empty? 
	puts "No vids found. Exiting." 
	exit
else
	puts "Found " + vids.length.to_s + " vids. Processing..."
end

progress_counter = 1
puts ""

CSV.open(outfile_path, "wb") do |csv|
  csv << ["FILENAME", "DIRNAME", "DURATION (SECS)", "FPS", "RESOLUTION", "VIDEO CODEC", "AUDIO SAMPLE RATE (Hz)", "AUDIO CODEC", "BITRATE (KB/S)", "SIZE (BYTES)", "VALID"]
  vids.each do | vid | 
    movie = FFMPEG::Movie.new(vid)
    csv << [File.basename(vid), File.dirname(vid), movie.duration, movie.frame_rate.to_f.round(2), movie.resolution, movie.video_codec, movie.audio_sample_rate, movie.audio_codec, movie.bitrate, movie.size, movie.valid?]
	print "\rProcessed #{progress_counter} of #{vids.length}"
	progress_counter += 1
  end
end

puts ""
puts "Done."
