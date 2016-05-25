#!/usr/bin/env ruby
$:.unshift File.expand_path("../lib", __FILE__)
################################################################################
# transcoderx.rb
# batch transcode video from batchmakerpro batch file
# current usage: transcoderx.rb [SOURCE_FILE] [DESTINATION_FILE]
## future usage: transcoderx.rb [CSV_BATCHFILE] [DESTINATION_DIR]
################################################################################
# TODO:
# - show how long each job takes
# - implement joining multipart VOBs
# --- ex: ffmpeg -i concat:VTS_01_0.VOB\|VTS_01_1.VOB\|VTS_01_2.VOB outfile.mp4
# ------- http://stackoverflow.com/a/8349419
###

require 'rubygems'
require 'bundler/setup'
Bundler.require
require 'csv'

batchfile = ARGV[0] || "./batchfile.csv"

# preservation format we want: 
#  Stream #0:0: Video: dvvideo, yuv411p, 720x480 [SAR 32:27 DAR 16:9], 28771 kb/s, 29.97 fps, 29.97 tbr, 29.97 tbn, 29.97 tbc
#  Stream #0:1: Audio: pcm_s16le, 48000 Hz, stereo, s16, 1536 kb/s
#  note: it seems ffmpeg defaults for ntsc-dvvideo are pretty much producing the above specs. 
preservation_format = "-target ntsc-dvvideo"

# access format we want?:
#  Stream #0:0(und): Video: h264 (High) (avc1 / 0x31637661), yuv420p, 640x480 [SAR 4:3 DAR 16:9], 1483 kb/s, 29.97 fps, 29.97 tbr, 30k tbn, 59.94 tbc (default)
#  Stream #0:1(und): Audio: aac (LC) (mp4a / 0x6134706D), 48000 Hz, stereo, fltp, 192 kb/s (default)
#  note: it seems ffmpeg defaults for ntsc-mp4 are pretty much producing the above specs. 
access_format_template = "-vcodec libx264 -s VIDEO_WIDTHxVIDEO_HEIGHT -b:v BITRATE_VALUE -acodec libfaac -ar 48000 " # WIP this is not quite right yet and will be changed based on new discusson

magic_quality_number = 0.23 # Make this higher for higher quality, lower for lower quality

puts <<BM
 _____________
< transcoderx >
 -------------
BM

def help(msg = nil)
  puts "ruby transcoderx.rb CSV_FILE SOURCE_ROOT DESTINATION_ROOT"
  puts msg if msg
  exit
end



help() unless ARGV[2]

help("CSV_FILE \"#{batchfile}\" does not exist") unless File.exist?(batchfile)
source_root = ARGV[1] || File.join('/', "Volumes","vid1")
help("SOURCE_ROOT value of \"#{source_root}\" does not exist") unless File.exist?(source_root)
destination_root = ARGV[2] || File.join('/', "Volumes","vid2")
help("DESTINATION_ROOT value of \"#{destination_root}\" does not exist") unless File.exist?(destination_root)

preservation_root = File.join(destination_root, 'preservation')
access_root = File.join(destination_root, 'access')

CSV.open(batchfile, "rb", headers: true) do |csv|
  csv.each do |row|
    next if row.header_row?
    file_name = row[0]
    dir_path = row[1]
    dir_path = dir_path[1..-1] if dir_path =~ /^\//
    video_source_path =  File.join(source_root, dir_path, file_name)
    access_dir = File.join(access_root, dir_path, file_name)
    FileUtils.makedirs(access_dir)
    # then we use this as part of the output path
    preservation_dir = File.join(preservation_root, dir_path, file_name)
    FileUtils.makedirs(preservation_dir)
    movie = FFMPEG::Movie.new(video_source_path)
    
    # Calculate desired bitrate based on video size and fps
    video_width = movie.width
    video_height = movie.height
    bitrate = (magic_quality_number * video_width * video_height * movie.frame_rate.to_f).ceil

    base_file_name = File.basename(video_source_path, File.extname(video_source_path))
    full_path_outfile = File.join(preservation_dir, "#{base_file_name}.dv")
    puts "Creating Preservation Master with ffmpeg args: " + preservation_format
    movie.transcode(full_path_outfile, preservation_format) { |progress| print "\rPercent complete: " + (progress * 100).to_i.to_s + "%"  }
    puts "Done with Preservation Master."

    # Swap values into access_format_template and create access copy
    access_format = access_format_template.gsub('VIDEO_WIDTH', video_width.to_s).gsub('VIDEO_HEIGHT', video_height.to_s).gsub('BITRATE_VALUE', bitrate.to_s)
    puts "Creating Access Copy with ffmpeg args: #{access_format}"
    full_path_outfile = File.join(access_dir, "#{base_file_name}.mp4")
    movie.transcode(full_path_outfile, access_format) { |progress| print "\rPercent complete: " + (progress * 100).to_i.to_s + "%"  }
    puts "Done with Access Copy."
  end
end
