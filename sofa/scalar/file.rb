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
		find_ancestor {|f| f.is_a?(Sofa::Set::Dynamic) && f.storage.persistent? }
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
		raise Sofa::Error::Forbidden unless permit? :read

		if ps = my[:persistent_sd]
			@body ||= ps.storage.val my[:persistent_name]
		end
		@body
	end

	def errors
		if (
			val['basename'] &&
			my[:options].is_a?(::Array) &&
			!my[:options].empty? &&
			!my[:options].include?(val['basename'].to_s[/\.([\w\.]+)$/,1])
		)
			[_ 'wrong file type']
		elsif (my[:max].to_i > 0) && (val['size'].to_i > my[:max])
			[_('too large') % {:min => my[:max]}]
		elsif (my[:min].to_i == 1) && val['size'].to_i < 1
			[_ 'mandatory']
		elsif (my[:min].to_i > 0) && (val['size'].to_i < my[:min])
			[_('too small') % {:min => my[:min]}]
		else
			[]
		end
	end

	def commit(type = :temp)
		if type == :temp && @action == :delete
			@val = {}
			@body = nil
		elsif type == :persistent && ps = my[:persistent_sd]
			case @action
				when :create,:update,nil
					ps.storage.store(
						my[:persistent_name],
						@body,
						val['basename'][/\.([\w\.]+)$/,1] || 'bin'
					) if @body && valid?
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
		hidden = <<_html if my[:min].to_i > 0 && val.empty?
	<input type="hidden" name="#{my[:short_name]}" value="" />
_html
		if (
			!val.empty? &&
			my[:min].to_i == 0 &&
			my[:parent].is_a?(Sofa::Set::Static) &&
			my[:parent][:item].find {|id,meta| id != my[:id] && meta[:klass] !~ /^meta-/ }
		)
			delete = <<_html
	<input type="submit" name="#{my[:short_name]}.action-delete" value="x">
_html
		end
		update = <<_html
	<input type="file" name="#{my[:short_name]}" class="#{_g_class arg}" />
_html
		<<_html.chomp
#{_g_default arg}
<span class="file">
#{hidden}#{delete}#{update}#{_g_errors arg}</span>
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
