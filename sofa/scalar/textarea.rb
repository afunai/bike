# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Textarea < Sofa::Field

	def errors
		if (my[:max].to_i > 0) && (val.size > my[:max])
			[_('too long: %{max} characters maximum') % {:max => my[:max]}]
		elsif (my[:min].to_i == 1) && val.empty?
			[_ 'mandatory']
		elsif (my[:min].to_i > 0) && (val.size < my[:min])
			[_('too short: %{min} characters minimum') % {:min => my[:min]}]
		else
			[]
		end
	end

	private

	def _g_create(arg)
		<<_html.chomp
<textarea name="#{my[:short_name]}" cols="#{my[:width]}" rows="#{my[:height]}" class="#{_g_class arg}">#{val}</textarea>#{_g_errors arg}
_html
	end
	alias :_g_update :_g_create

	def val_cast(v)
		v.to_s
	end

end
