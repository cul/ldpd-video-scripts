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
access_format_template = "-vcodec libx264 -s VIDEO_WIDTHxVIDEO_HEIGHT -b:v BITRATE_VALUE -pix_fmt yuv420p -acodec libfaac -ar 48000" # WIP this is not quite right yet and will be changed based on new discusson

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



help() unless ARGV[0]

help("CSV_FILE \"#{batchfile}\" does not exist") unless File.exist?(batchfile)
source_root = ARGV[1] || File.join('/', "Volumes","vid1")
help("SOURCE_ROOT value of \"#{source_root}\" does not exist") unless File.exist?(source_root)
destination_root = ARGV[2] || File.join('/', "Volumes","vid2")
help("DESTINATION_ROOT value of \"#{destination_root}\" does not exist") unless File.exist?(destination_root)

preservation_root = File.join(destination_root, 'preservation')
access_root = File.join(destination_root, 'access')

CSV.open(batchfile, "rb", headers: true) do |csv|
  video_counter = 0
  num_videos = csv.readlines.size - 1 # Subtract one line for headers
  csv.rewind # Go back to the beginning of the file
  
  CSV.open('transcoded.csv', 'wb') do |report|
    report << ['FILENAME', 'DIRNAME', "DURATION (SECS)", "FPS", "RESOLUTION", "VIDEO CODEC", "AUDIO SAMPLE RATE (Hz)", "AUDIO CODEC", "BITRATE (KB/S)", "SIZE (BYTES)", "VALID", 'PROBLEM FOUND?', 'PROBLEM DESCRIPTION', 'KEYWORDS']
    csv.each do |row|
      next if row.header_row?
      
      report.flush
      
      video_counter += 1
      puts "Transcoding video #{video_counter} of #{num_videos}..."
      
      file_name = row[0]
      dir_path = row[1]
      dir_path = dir_path[1..-1] if dir_path =~ /^\//
      video_source_path =  File.join(source_root, dir_path, file_name)

      # build the output path
      access_dir = File.join(access_root, dir_path)
      FileUtils.makedirs(access_dir)

      access_file_name = File.basename(video_source_path) + ".mp4"
      full_path_outfile = File.join(access_dir, access_file_name)
      
      # Make sure that original video file exists
      unless File.exist?(video_source_path)
        report << [access_file_name, access_dir, '', '', '', '', '', '', '', '','', true, "Source video not found"]
        next
      end
      
      begin
        movie = FFMPEG::Movie.new(video_source_path)
        original_movie_duration = movie.duration
      rescue StandardError
        report << [access_file_name, access_dir, true, "FFMPEG::Movie cannot open sourcefile"]
        next
      end  
      
      # If transcoded copy already exists, don't re-generate it. Otherwise do generate it.
      if File.exists?(full_path_outfile)
        puts "--> Skipped access copy generation because file already exists."
      else
        # Calculate desired bitrate based on video size and fps
        video_width = movie.width
        video_height = movie.height
        bitrate = (magic_quality_number * video_width * video_height * movie.frame_rate.to_f).ceil
  
        # Swap values into access_format_template and create access copy
        access_format = access_format_template.gsub('VIDEO_WIDTH', video_width.to_s).gsub('VIDEO_HEIGHT', video_height.to_s).gsub('BITRATE_VALUE', bitrate.to_s)
        puts "Creating Access Copy with ffmpeg args: #{access_format}"
        
        begin
          movie.transcode(full_path_outfile, access_format) { |progress| print "\rPercent complete: " + (progress * 100).to_i.to_s + "%"  }
        rescue StandardError
          report << [access_file_name, access_dir, '', '', '', '', '', '', '', '','', true, "FFMPEG::Movie cannot transcode sourcefile"]
          next
        end
      end
      
      # Extract technical data from generated access copy
      access_copy_movie = FFMPEG::Movie.new(full_path_outfile)
      
      # Verify that access copy movie duration equals original movie duration
      
      if original_movie_duration.to_i != access_copy_movie.duration.to_i # Round to nearest integer to ignore floating point errors
        report << [access_file_name, access_dir, '', '', '', '', '', '', '', '','', true, "Access copy duration is not the same as the original!"]
      else
        report << [access_file_name, access_dir, access_copy_movie.duration, access_copy_movie.frame_rate.to_f.round(2), access_copy_movie.resolution, access_copy_movie.video_codec, access_copy_movie.audio_sample_rate, access_copy_movie.audio_codec, access_copy_movie.bitrate, access_copy_movie.size, access_copy_movie.valid?]
      end
      
      puts "Done generating access copy."
    end
  end
end
