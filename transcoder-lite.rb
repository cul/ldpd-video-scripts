#!/usr/bin/env ruby
$:.unshift File.expand_path("../lib", __FILE__)
################################################################################
# transcoder-lite.rb
################################################################################

require 'rubygems'
require 'bundler/setup'

Bundler.require

file_to_transcode = ARGV[0]

# preservation format we want: 
#  Stream #0:0: Video: dvvideo, yuv411p, 720x480 [SAR 32:27 DAR 16:9], 28771 kb/s, 29.97 fps, 29.97 tbr, 29.97 tbn, 29.97 tbc
#  Stream #0:1: Audio: pcm_s16le, 48000 Hz, stereo, s16, 1536 kb/s
#  note: it seems ffmpeg defaults for ntsc-dvvideo are pretty much producing the above specs. 
preservation_format = "-target ntsc-dvvideo"

# access format we want?:
#  Stream #0:0(und): Video: h264 (High) (avc1 / 0x31637661), yuv420p, 640x480 [SAR 4:3 DAR 16:9], 1483 kb/s, 29.97 fps, 29.97 tbr, 30k tbn, 59.94 tbc (default)
#  Stream #0:1(und): Audio: aac (LC) (mp4a / 0x6134706D), 48000 Hz, stereo, fltp, 192 kb/s (default)
#  note: it seems ffmpeg defaults for ntsc-mp4 are pretty much producing the above specs. 
access_format_template = "-vcodec libx264 -s VIDEO_WIDTHxVIDEO_HEIGHT -b:v BITRATE_VALUE -pix_fmt yuv420p -acodec libfaac -ar 48000" # WIP this is not quite right yet and will be changed based on new discusson

magic_quality_number = 0.23 # Make this higher for higher quality, lower for lower quality

puts ' __________________ '
puts ' < transcoder-lite > '
puts ' __________________ '

def help(msg = nil)
  puts "ruby transcoder-lite.rb FILE_TO_CONVERT"
  puts msg if msg
  exit
end

movie = FFMPEG::Movie.new(file_to_transcode)

# Calculate desired bitrate based on video size and fps
video_width = movie.width
video_height = movie.height
bitrate = (magic_quality_number * video_width * video_height * movie.frame_rate.to_f).ceil

# Swap values into access_format_template and create access copy
access_format = access_format_template.gsub('VIDEO_WIDTH', video_width.to_s).gsub('VIDEO_HEIGHT', video_height.to_s).gsub('BITRATE_VALUE', bitrate.to_s)
puts "Creating Access Copy with ffmpeg args: #{access_format}"

begin
  movie.transcode(file_to_transcode + '.mp4', access_format) { |progress| print "\rPercent complete: " + (progress * 100).to_i.to_s + "%"  }
rescue StandardError
  puts "Error: FFMPEG::Movie cannot transcode sourcefile"
end
