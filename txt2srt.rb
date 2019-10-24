#!/usr/bin/env ruby

require 'time'

class SubtitleCollection
	attr_reader :subtitles

	def initialize()
		@subtitles = []
	end

	def add(subtitle)
		@subtitles.push subtitle
	end

	def to_s
		str = ""
		index = 0
		@subtitles.each do |subtitle|
			index += 1
			str = "#{str}#{index.to_s}\n"
			str = "#{str}#{subtitle}\n"
		end
		str
	end
end

class Subtitle
	attr_reader :start_time, :end_time, :text

	def initialize(start_time, end_time, text)
		@start_time = start_time
		@end_time = end_time
		@text = text
	end

	def to_s
		"#{start_time} --> #{end_time}\n#{text}"
	end
end

class Timecode
	attr_reader :hours, :minutes, :seconds, :milliseconds

	def initialize(hours, minutes, seconds, milliseconds)
		@hours = hours
		@minutes = minutes
		@seconds = seconds
		@milliseconds = milliseconds
	end

	def to_s
		"#{'%02d' % hours}:#{'%02d' % minutes}:#{'%02d' % seconds},#{'%03d' % milliseconds}"
	end
end

class FrameTimecode < Timecode
	def self.parse(str, offset = 0)
		components = str.split(':')
		return FrameTimecode.new(
			components[0].to_i - 1,
			components[1].to_i,
			components[2].to_i,
			components[3].to_i,
			offset
		)
	end

	attr_reader :frame

	def initialize(hours, minutes, seconds, frame, offset = 0)
		milliseconds = frame * (1000 / 24)
		if offset > 0 then
			time = Time.parse("#{'%02d' % hours}:#{'%02d' % minutes}:#{'%02d' % seconds},#{'%03d' % milliseconds}")
			time = time + offset
			super(time.hour, time.min, time.sec, milliseconds)
		else
			super(hours, minutes, seconds, milliseconds)
		end
	end
end

def convert_file(file, offset = 0)
	subtitles = SubtitleCollection.new
	File.open(file, 'r') do |f|
		line_number = 0
		current_start_time = nil
		current_end_time = nil
		current_text = ""
		f.each_line do |line|
			line_number += 1
			if line.start_with?('DUB') then
				current_start_time = FrameTimecode.parse(line[8, 11], offset)
				current_end_time = FrameTimecode.parse(line[20, 11], offset)
			elsif line.to_s.length == 1 then
				if current_start_time != nil && current_end_time != nil && current_text.length > 0 then
					subtitles.add(
						Subtitle.new(
							current_start_time,
							current_end_time,
							current_text
						)
					)
				end
				current_start_time = nil
				current_end_time = nil
				current_text = ""
			else
				if current_text.length > 0 then
					current_text += "\n"
				end
				current_text = "#{current_text}#{line}"
			end
		end
	end
	output_file = File.join(File.dirname(file), "#{File.basename(file, '.*')}.srt")
	File.open(output_file, 'w') { |f| f.write(subtitles) }
	puts "Converted '#{file}' to '#{output_file}'."
end

source = ARGV[0]
offset = ARGV[1]

if source != nil then
	if File.directory?(source) then
		Dir.glob(File.join(source, '*.txt')) do |file|	
			if offset != nil then
				convert_file(file, offset.to_i)
			else
				convert_file(file)
			end
		end
	else
		if offset != nil then
			convert_file(source, offset.to_i)
		else
			convert_file(source)
		end
	end
else
	puts "Not enough parameters."
	puts "Usage: #{File.basename($PROGRAM_NAME)} INPUT_FILE|FOLDER [OFFSET_SECONDS]"
end

