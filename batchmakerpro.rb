#!/usr/bin/env ruby
################################################################################
# batchmakerpro.rb
# video analyzer, prober, and csv batch-list maker
################################################################################

require 'rubygems'
require 'bundler/setup'
Bundler.require
require 'csv'

source_dir = ARGV[0] || "."
dest_dir = ARGV[1] || "."

puts <<BM
 _______________
< batchmakerpro >
 ---------------
BM

puts "Source dir: "+source_dir
puts "CSV destination dir: "+dest_dir

vids = Dir.glob("#{source_dir}/**/*.{mp4,vob,wmv,avi,mpg,mpeg,asf,mov,3gp,m4v,flv}", File::FNM_CASEFOLD)
if vids.empty? 
	puts "No vids found. Exiting." 
	exit
else
	puts "Found " + vids.length.to_s + " vids. Processing..."
end

CSV.open(dest_dir+"/batchfile.csv", "wb") do |csv|
  csv << ["FILENAME", "DIRNAME", "DURATION (SECS)", "FPS", "RESOLUTION", "VIDEO CODEC", "AUDIO SAMPLE RATE (Hz)", "AUDIO CODEC", "BITRATE (KB/S)", "SIZE (BYTES)", "VALID"]
  vids.each do | vid | 
    movie = FFMPEG::Movie.new(vid)
    csv << [File.basename(vid), File.dirname(vid), movie.duration, movie.frame_rate.to_f, movie.resolution, movie.video_codec, movie.audio_sample_rate, movie.audio_codec, movie.bitrate, movie.size, movie.valid?]
  end
end

puts "Done."
