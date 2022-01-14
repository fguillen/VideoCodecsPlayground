require "benchmark"
require "json"
require "erb"
require "csv"

class Script
  INPUT_PATH = "#{__dir__}/original.mp4"
  HTML_TEMPLATE = "#{__dir__}/index.html.erb"

  OUTPUT_BASE_PATH = "#{__dir__}/results"
  LOG_PATH = "#{OUTPUT_BASE_PATH}/log_#{Time.now.to_i}.log"
  CSV_OUTPUT = "#{OUTPUT_BASE_PATH}/results.csv"
  HTML_OUTPUT = "#{OUTPUT_BASE_PATH}/index.html"

  VARIANTS = [
    # # Examples from here: https://trac.ffmpeg.org/wiki/Encode/VP9
    # {
    #   name: "Webm Average Bitrate (ABR)",
    #   container: "webm",
    #   video_codec: "vp9",
    #   audio_codec: "opus",
    #   command: "ffmpeg -i #INPUT -c:v libvpx-vp9 -b:v 2M -c:a libopus #OUTPUT"
    # },
    # {
    #   name: "Webm Two-Pass",
    #   container: "webm",
    #   video_codec: "vp9",
    #   audio_codec: "opus",
    #   command: "ffmpeg -i #INPUT -c:v libvpx-vp9 -b:v 2M -pass 1 -an -f null /dev/null && ffmpeg -i #INPUT -c:v libvpx-vp9 -b:v 2M -pass 2 -c:a libopus #OUTPUT"
    # },
    # {
    #   name: "Webm Constant Quality",
    #   container: "webm",
    #   video_codec: "vp9",
    #   audio_codec: "opus",
    #   command: "ffmpeg -i #INPUT -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus #OUTPUT"
    # },
    # {
    #   name: "Webm Constrained Quality",
    #   container: "webm",
    #   video_codec: "vp9",
    #   audio_codec: "opus",
    #   command: "ffmpeg -i #INPUT -c:v libvpx-vp9 -crf 30 -b:v 2000k -c:a libopus #OUTPUT"
    # },
    # {
    #   name: "Webm Constant Bitrate",
    #   container: "webm",
    #   video_codec: "vp9",
    #   audio_codec: "opus",
    #   command: "ffmpeg -i #INPUT -c:v libvpx-vp9 -minrate 1M -maxrate 1M -b:v 1M -c:a libopus #OUTPUT"
    # },
    # {
    #   name: "Webm Lossless",
    #   container: "webm",
    #   video_codec: "vp9",
    #   audio_codec: "opus",
    #   command: "ffmpeg -i #INPUT -c:v libvpx-vp9 -lossless 1 -c:a libopus #OUTPUT"
    # },


    # # Examples from here: https://trac.ffmpeg.org/wiki/Encode/H.264
    # {
    #   name: "MP4 Constant Quality preset slow",
    #   container: "mp4",
    #   video_codec: "avc1",
    #   audio_codec: "aac",
    #   command: "ffmpeg -i #INPUT -c:v libx264 -preset slow -crf 22 -c:a aac #OUTPUT"
    # },
    # {
    #   name: "MP4 Constant Quality preset medium",
    #   container: "mp4",
    #   video_codec: "avc1",
    #   audio_codec: "aac",
    #   command: "ffmpeg -i #INPUT -c:v libx264 -preset medium -crf 22 -c:a aac #OUTPUT"
    # },
    # {
    #   name: "MP4 Constant Quality preset veryslow",
    #   container: "mp4",
    #   video_codec: "avc1",
    #   audio_codec: "aac",
    #   command: "ffmpeg -i #INPUT -c:v libx264 -preset veryslow -crf 22 -c:a aac #OUTPUT"
    # },
    {
      name: "MP4 Two-Pass",
      container: "mp4",
      video_codec: "avc1",
      audio_codec: "aac",
      command: "ffmpeg -y -i #INPUT -c:v libx264 -b:v 2600k -pass 1 -an -f mp4 /dev/null && ffmpeg -i #INPUT -c:v libx264 -b:v 2600k -pass 2 -c:a aac -b:a 128k #OUTPUT"
    },
    # {
    #   name: "MP4 Lossless H.264",
    #   container: "mp4",
    #   video_codec: "avc1",
    #   audio_codec: "aac",
    #   command: "ffmpeg -i #INPUT -c:v libx264 -c:a aac -qp 0 #OUTPUT"
    # },

    # # Examples from here: https://gist.github.com/Vestride/278e13915894821e1d6f


    # # Other examples
    # {
    #   name: "MP4 no params",
    #   container: "mp4",
    #   video_codec: "avc1",
    #   audio_codec: "aac",
    #   command: "ffmpeg -i #INPUT -c:v libx264 -c:a aac #OUTPUT"
    # },
    # {
    #   name: "Webm no params",
    #   container: "webm",
    #   video_codec: "vp9",
    #   audio_codec: "opus",
    #   command: "ffmpeg -i #INPUT -c:v libvpx-vp9 -c:a libopus #OUTPUT"
    # },
    # {
    #   name: "Webm Constant Bitrate - 360p",
    #   container: "webm",
    #   video_codec: "vp9",
    #   audio_codec: "opus",
    #   command: "ffmpeg -i #INPUT -c:v libvpx-vp9 -minrate 1M -maxrate 1M -b:v 1M -c:a libopus -filter:v \"scale=-1:'min(360,ih)'\" #OUTPUT"
    # },
    # {
    #   name: "Webm Constant Bitrate - 480p",
    #   container: "webm",
    #   video_codec: "vp9",
    #   audio_codec: "opus",
    #   command: "ffmpeg -i #INPUT -c:v libvpx-vp9 -minrate 1M -maxrate 1M -b:v 1M -c:a libopus -filter:v \"scale=-1:'min(480,ih)'\" #OUTPUT"
    # },
    # {
    #   name: "Webm Constant Bitrate - 720p",
    #   container: "webm",
    #   video_codec: "vp9",
    #   audio_codec: "opus",
    #   command: "ffmpeg -i #INPUT -c:v libvpx-vp9 -minrate 1M -maxrate 1M -b:v 1M -c:a libopus -filter:v \"scale=-1:'min(720,ih)'\" #OUTPUT"
    # },
    # {
    #   name: "Webm Constant Bitrate - 1080p",
    #   container: "webm",
    #   video_codec: "vp9",
    #   audio_codec: "opus",
    #   command: "ffmpeg -i #INPUT -c:v libvpx-vp9 -minrate 1M -maxrate 1M -b:v 1M -c:a libopus -filter:v \"scale=-1:'min(1080,ih)'\" #OUTPUT"
    # },
  ]

  def run
    puts "Starting script ..."
    # write_csv_headers

    VARIANTS.each do |variant|
      puts "Executing variant: #{variant[:name]}"
      result = execute_variant(variant, INPUT_PATH, OUTPUT_BASE_PATH)
      log(JSON.pretty_generate(result))
      # write_csv(result)
    end
    puts "End of script!"
  end

  def log(message)
    File.open(LOG_PATH, "a") do |file|
      file.puts message
    end
  end

  def write_csv_headers
    headers = [
      "id",
      "name",
      "container",
      "video_codec",
      "audio_codec",
      "command",
      "filename",
      "output_url",
      "ffmpeg_command",
      "time",
      "time_formatted",
      "original_file_size",
      "compressed_file_size",
      "compression_ratio"
    ]
    File.open(CSV_OUTPUT, "w") do |file|
      file.puts CSV.generate_line headers
    end
  end

  def write_csv(result)
    File.open(CSV_OUTPUT, "a") do |file|
      file.puts CSV.generate_line result.values
    end
  end

  def read_results_from_csv
    CSV.open(CSV_OUTPUT, headers: :first_row).map(&:to_h)
  end

  def execute_variant(variant, input_path, output_base_path)
    filename = [variant[:name], variant[:video_codec], variant[:audio_codec]].join("_").gsub(/\W/, "_")
    filename += ".#{variant[:container]}"
    output_path = "#{output_base_path}/#{filename}"
    ffmpeg_command = variant[:command].gsub("#INPUT", input_path).gsub("#OUTPUT", output_path)
    ffmpeg_command.gsub!("ffmpeg", "ffmpeg -y")
    time = command(ffmpeg_command)
    original_file_size = File.size(input_path) # Yes I know I should cache this ;)
    compressed_file_size = File.size(output_path)
    compression_ratio = compressed_file_size * 100 / original_file_size.to_f

    {
      id: filename.split(".")[0],
      **variant,
      filename: filename,
      output_url: filename,
      ffmpeg_command: ffmpeg_command,
      time: time.truncate(2),
      time_formatted: seconds_to_hms(time),
      original_file_size: original_file_size,
      compressed_file_size: compressed_file_size,
      compression_ratio: compression_ratio.truncate(2)
    }
  end

  def command(command_string)
    puts("Executing command: '#{command_string}'")

    Benchmark.realtime do
      system(command_string, exception: true)
    end
  end

  def render_html
    puts "Rendering HTML"
    results = read_results_from_csv
    renderer = ERB.new(File.read(HTML_TEMPLATE))
    html = renderer.result_with_hash({ results: results })

    File.open(HTML_OUTPUT, "w") do |file|
      file.write html
    end
  end

  def seconds_to_hms(seconds)
    "%02d:%02d:%02d" % [seconds / 3600, seconds / 60 % 60, seconds % 60]
  end
end

Script.new.run
# Script.new.render_html



#     ffmpeg -i original.webm -c:v libx264 -crf 22 -c:a libopus -movflags +faststart video_7.mp4

#     ffmpeg -i original.webm -vcodec libvpx-vp9 -b:v 1M -acodec libvorbis video_10.webm

#      ffmpeg -i original.webm -vcodec libvpx-vp9 -b:v 1M -acodec libvorbis -movflags +faststart video_11.webm

# ffmpeg -i original.webm -vcodec libvpx-vp9 -b:v 1M -acodec libopus -movflags +faststart video_12.webm

# ** Google recommemdation :: INI **

# ffmpeg -i original.webm -c:v libvpx-vp9 -pass 1 -b:v 1000K -threads 1 -speed 4 \
#   -tile-columns 0 -frame-parallel 0 -auto-alt-ref 1 -lag-in-frames 25 \
#   -g 9999 -aq-mode 0 -an -f webm /dev/null

# ffmpeg -i original.webm -c:v libvpx-vp9 -pass 2 -b:v 1000K -threads 1 -speed 0 \
#   -tile-columns 0 -frame-parallel 0 -auto-alt-ref 1 -lag-in-frames 25 \
#   -g 9999 -aq-mode 0 -c:a libopus -b:a 64k -f webm video_13.webm

# ** Google recommemdation :: END **

#  ffmpeg -an -i original.webm -vcodec libx264 -pix_fmt yuv420p -profile:v baseline -level 3 video_14.mp4

# ffmpeg  -i original.webm -vcodec libx264 -pix_fmt yuv420p -profile:v baseline -level 3 video_15.mp4

# ffmpeg -i original.webm -vcodec h264 -acodec aac -pix_fmt yuv420p -profile:v baseline -level 3 video_16.mp4


# ffmpeg -i original.webm -vcodec h264 -acodec aac -pix_fmt yuv420p -profile:v baseline -level 3  -vf "drawtext=text='mp4 h264 aaac':x=100:y=H-th-100:fontsize=64:fontcolor=white:shadowcolor=black:shadowx=5:shadowy=5" video_17.mp4

# ffmpeg -i original.webm -vcodec libx265 -acodec aac -pix_fmt yuv420p -vf "drawtext=text='mp4 libx265 aaac':x=100:y=H-th-100:fontsize=64:fontcolor=white:shadowcolor=black:shadowx=5:shadowy=5" video_18.mp4

# ffmpeg -i original.webm -vcodec libvpx-vp9 -acodec libopus -movflags +faststart -filter:v "scale='min(1280,iw)':-1" video_19.webm

# ffmpeg -i original.webm -vcodec libvpx-vp9 -acodec libopus -movflags +faststart -filter:v "scale='min(1920,iw)':-1" video_20.webm

#  ffmpeg -i original.webm -vcodec h264 -acodec aac -pix_fmt yuv420p -profile:v baseline -level 3 -filter:v "scale='min(1280,iw)':-1"  video_21.mp4


# This is working well:

#     ffmpeg -i original.webm -c:v libvpx-vp9 -crf 22 -c:a libopus -movflags +faststart video_8.webm
# # H265
# ffmpeg -i input.mp4 -c:v libx265 -crf 23 -tag:v hvc1 -pix_fmt yuv420p -color_primaries 1 -color_trc 1 -colorspace 1 -movflags +faststart -an output.mp4

# # VP9
# ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 30 -speed 3 -pix_fmt yuv420p -color_primaries 1 -color_trc 1 -colorspace 1 -movflags +faststart -an output.webm


# ffmpeg -i input.mp4 -c:v libvpx-vp9 -lossless 1 output.webm
