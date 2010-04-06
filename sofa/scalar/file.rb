# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::File < Sofa::Field

	attr_reader :body

	def initialize(meta = {})
		super
	end

	def meta_path
		my[:full_name].gsub('-','/')
	end

	def meta_persistent_sd
		f = self
		f = f[:parent] until f.nil? || f.is_a?(Sofa::Set::Dynamic) && f.storage.persistent?
		f
	end

	def meta_persistent_name
		f    = my[:parent]
		ps   = my[:persistent_sd]
		name = my[:id]
		until f == ps
			name = "#{f[:id]}-#{name}"
			f = f[:parent]
		end
		name
	end

def errors
return []

	if (my[:max].to_i > 0) && (val.size > my[:max])
		['too large']
	elsif (my[:min].to_i == 1) && val.empty?
		['mandatory']
	elsif (my[:min].to_i > 0) && (val.size < my[:min])
		['too small']
	else
		[]
	end
end

def commit(type = :temp)
	super
end

	private

	def _g_update(arg)
		<<_html.chomp
<span class="file">
#{_g_fileinfo arg}
	<input type="file" name="#{my[:short_name]}" class="#{_g_class arg}" />#{_g_errors arg}
</span>
_html
	end
	alias :_g_create :_g_update

	def _g_fileinfo(arg = {})
		<<_html.chomp unless val.empty?
	<a href="#{my[:path]}">#{val['basename']} (#{val['size']} bytes)</a>
_html
	end

	def val_cast(v)
		if v && v[:tempfile]
			v[:tempfile].rewind
			@body = v[:tempfile].read
		end

		if @body
			{
				'basename' => File.basename(v[:filename]),
				'type'     => v[:type],
				'size'     => @body.size,
			}
		elsif v.is_a? ::Hash
			v
		else
			{}
		end
	end

end
