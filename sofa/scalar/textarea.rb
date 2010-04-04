# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Textarea < Sofa::Field

	def errors
		if (my[:max].to_i > 0) && (val.size > my[:max])
			['too long']
		elsif (my[:min].to_i == 1) && val.empty?
			['mandatory']
		elsif (my[:min].to_i > 0) && (val.size < my[:min])
			['too short']
		else
			[]
		end
	end

	private

	def _g_create(arg)
		<<_html.chomp
<textarea name="#{my[:short_name]}" cols="#{my[:width]}" rows="#{my[:height]}" class="#{_g_class arg}">#{val}</textarea>
_html
	end
	alias :_g_update :_g_create

	def val_cast(v)
		v.to_s
	end

end


class Sofa::Textarea::Pre < Sofa::Textarea

	def _g_default(arg)
		'<pre>' + Rack::Utils.escape_html(val.to_s) + '</pre>'
	end

end
