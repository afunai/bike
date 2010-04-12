# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::File < Sofa::Field

	def initialize(meta = {})
		super
	end

	def meta_path
		my[:full_name].gsub('-','/')
	end

	def meta_tmp_path
		"/#{Sofa.base[:tid]}/#{my[:short_name].gsub('-','/')}" if Sofa.base
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

	def body
		if ps = my[:persistent_sd]
			@body ||= ps.storage.val my[:persistent_name]
		end
		@body
	end

	def errors
		if (
			body &&
			my[:options].is_a?(::Array) &&
			!my[:options].empty? &&
			!my[:options].include?(val['basename'].to_s[/\.([\w\.]+)$/,1])
		)
			['wrong file type']
		elsif (my[:max].to_i > 0) && (val['size'].to_i > my[:max])
			['too large']
		elsif (my[:min].to_i == 1) && val['size'].to_i < 1
			['mandatory']
		elsif (my[:min].to_i > 0) && (val['size'].to_i < my[:min])
			['too small']
		else
			[]
		end
	end

	def commit(type = :temp)
		if valid? && type == :persistent && ps = my[:persistent_sd]
			case @action
				when :create,:update,nil
					ps.storage.store(
						my[:persistent_name],
						@body,
						val['basename'][/\.([\w\.]+)$/,1] || 'bin'
					) if @body
				when :delete
					ps.storage.delete my[:persistent_name]
			end
		end
		super
	end

	private

	def _g_default(arg = {})
		path     = [:read,nil].include?(arg[:action]) ? my[:path] : my[:tmp_path]
		basename = Rack::Utils.escape_html val['basename'].to_s
		type     = Rack::Utils.escape_html val['type'].to_s
		<<_html.chomp unless val.empty?
<span class="file"><a href="#{path}/#{basename}">#{basename} (#{val['size']} bytes)</a></span>
_html
	end

	def _g_update(arg)
		<<_html.chomp
#{_g_default arg}
<span class="file">
	<input type="file" name="#{my[:short_name]}" class="#{_g_class arg}" />#{_g_errors arg}
</span>
_html
	end
	alias :_g_create :_g_update

	def val_cast(v)
		if v && v[:tempfile]
			v[:tempfile].rewind
			@body = v[:tempfile].read
			{
				'basename' => File.basename(v[:filename]),
				'type'     => v[:type] || 'application/octet-stream',
				'size'     => @body.size,
			}
		elsif v.is_a?(::Hash) && v['basename']
			{
				'basename' => v['basename'].to_s,
				'type'     => v['type'].to_s,
				'size'     => v['size'].to_i,
			}
		else
			{}
		end
	end

end
