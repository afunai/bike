# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

begin
	require 'quick_magick'
rescue LoadError
end

class Sofa::Img < Sofa::File

	def self.quick_magick?
		Object.const_defined? :QuickMagick
	end

	def thumbnail
		raise Sofa::Error::Forbidden unless permit? :read

		if ps = my[:persistent_sd]
			@thumbnail ||= ps.storage.val "#{my[:persistent_name]}_small"
		end
		@thumbnail || body
	end

	def errors
		if @error_thumbnail
			[_("wrong file type: should be %{types}") % {:types => my[:options].join('/')}]
		else
			super
		end
	end

	def commit(type = :temp)
		super
		if type == :temp && @action == :delete
			@thumbnail = nil
		elsif type == :persistent && ps = my[:persistent_sd]
			case @action
				when :create,:update,nil
					ps.storage.store(
						"#{my[:persistent_name]}_small",
						@thumbnail,
						val['basename'][/\.([\w\.]+)$/,1] || 'bin'
					) if @thumbnail && valid?
			end
		end
	end

	private

	def _g_default(arg = {})
		path       = [:read,nil].include?(arg[:action]) ? my[:path] : my[:tmp_path]
		basename   = Rack::Utils.escape_html val['basename'].to_s
		s_basename = basename.sub(/\..+$/,'_small\\&')
		<<_html.chomp unless val.empty?
<span class="img">
	<a href="#{path}/#{basename}"><img src="#{path}/#{s_basename}" /></a>
</span>
_html
	end

	def _thumbnail(tempfile)
		@error_thumbnail = nil
		begin
			tempfile.rewind
			img = QuickMagick::Image.read(tempfile.path).first
			img.resize "#{my[:width]}x#{my[:height]}"
			img.to_blob
		rescue QuickMagick::QuickMagickError
			@error_thumbnail = $!.inspect
			nil
		end if self.class.quick_magick?
	end

	def val_cast(v)
		@thumbnail = _thumbnail(v[:tempfile]) if v && v[:tempfile]
		super
	end

end
