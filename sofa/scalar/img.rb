# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

begin
	require 'quick_magick'
rescue LoadError
end

class Sofa::Img < Sofa::File

	def self.thumbnail?
		Object.const_defined? :QuickMagick
	end

	def thumbnail
		raise Sofa::Error::Forbidden unless permit? :read

		if ps = my[:persistent_sd]
			@thumbnail ||= ps.storage.val "#{my[:persistent_name]}.small"
		end
		@thumbnail || body
	end

	def errors
		if nil # malformed image
		else
			super
		end
	end

	def commit(type = :temp)
		if type == :temp && @action == :delete
			@thumbnail = nil
		elsif type == :persistent && ps = my[:persistent_sd]
			case @action
				when :create,:update,nil
					ps.storage.store(
						"#{my[:persistent_name]}.small",
						@thumbnail,
						val['basename'][/\.([\w\.]+)$/,1] || 'bin'
					) if @thumbnail && valid?
			end
		end
		super
	end

	private

	def _g_default(arg = {})
		path       = [:read,nil].include?(arg[:action]) ? my[:path] : my[:tmp_path]
		basename   = Rack::Utils.escape_html val['basename'].to_s
		s_basename = basename.sub(/\.[^\.]+$/,'.small\\&')
		<<_html.chomp unless val.empty?
<span class="img">
	<a href="#{path}/#{basename}"><img href="#{path}/#{s_basename}" /></a>
</span>
_html
	end

	def _thumbnail(tempfile)
		if self.class.thumbnail?
			tempfile.rewind
			img = QuickMagick::Image.read(tempfile.path).first
			img.resize '10x10'
			img.to_blob
		end
	end

	def val_cast(v)
		@thumbnail = _thumbnail(v[:tempfile]) if v && v[:tempfile]
		super
	end

end
