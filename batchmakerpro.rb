#!/usr/bin/env ruby
################################################################################
# batchmakerpro.rb
# video analyzer, prober, and csv batch-list maker
################################################################################

require 'rubygems'
require 'bundler/setup'
Bundler.require
require 'csv'

folder = ARGV[0] #"."
vids = Dir.glob("#{folder}/**/*.{mp4,vob,wmv,avi,mpg,asf,mov}", File::FNM_CASEFOLD)
CSV.open("./file.csv", "wb") do |csv|
  csv << ["source_path", "duration"]
  vids.each do | vid | 
	fullpath = vid
	puts fullpath
    movie = FFMPEG::Movie.new(fullpath)
    csv << [fullpath, movie.duration.to_s]
  end
end
