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
vids = Dir.glob("#{source_dir}/**/*.{mp4,vob,wmv,avi,mpg,asf,mov}", File::FNM_CASEFOLD)

CSV.open("./batchfile.csv", "wb") do |csv|
  csv << ["FILENAME", "DIRNAME", "DURATION (SECS)", "FPS", "RESOLUTION", "VIDEO CODEC", "AUDIO SAMPLE RATE (Hz)", "AUDIO CODEC", "BITRATE (KB/S)", "SIZE (BYTES)"]
  vids.each do | vid | 
    movie = FFMPEG::Movie.new(vid)
    csv << [File.basename(vid), File.dirname(vid), movie.duration.to_s, movie.frame_rate.to_s, movie.resolution.to_s, movie.video_codec.to_s, movie.audio_sample_rate.to_s, movie.audio_codec.to_s, movie.bitrate.to_s, movie.size.to_s]
  end
end
