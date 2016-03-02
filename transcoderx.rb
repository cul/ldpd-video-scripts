#!/usr/bin/env ruby
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
full_path_outfile = ARGV[1] || "./transcodes"

# preservation format we want: 
#  Stream #0:0: Video: dvvideo, yuv411p, 720x480 [SAR 32:27 DAR 16:9], 28771 kb/s, 29.97 fps, 29.97 tbr, 29.97 tbn, 29.97 tbc
#  Stream #0:1: Audio: pcm_s16le, 48000 Hz, stereo, s16, 1536 kb/s
#  note: it seems ffmpeg defaults for ntsc-dvvideo are pretty much producing the above specs. 
preservation_format = "-target ntsc-dvvideo"

# access format we want?:
#  Stream #0:0(und): Video: h264 (High) (avc1 / 0x31637661), yuv420p, 640x480 [SAR 4:3 DAR 16:9], 1483 kb/s, 29.97 fps, 29.97 tbr, 30k tbn, 59.94 tbc (default)
#  Stream #0:1(und): Audio: aac (LC) (mp4a / 0x6134706D), 48000 Hz, stereo, fltp, 192 kb/s (default)
#  note: it seems ffmpeg defaults for ntsc-mp4 are pretty much producing the above specs. 
access_format = "-target ntsc-mpeg4"


puts <<BM
 _____________
< transcoderx >
 -------------
BM

movie = FFMPEG::Movie.new(batchfile)

puts "Creating Preservation Master"
movie.transcode(full_path_outfile + ".dv", preservation_format) { |progress| print "\rPercent complete: " + (progress * 100).to_i.to_s + "%"  }
puts "Done."

puts "Creating Access Copy"
movie.transcode(full_path_outfile + ".mp4") { |progress| print "\rPercent complete: " + (progress * 100).to_i.to_s + "%"  }
puts "Done."
