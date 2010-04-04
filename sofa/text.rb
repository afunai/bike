# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Text < Sofa::Field

	def initialize(meta = {})
		meta[:size] = $&.to_i if meta[:tokens] && meta[:tokens].first =~ /^\d+$/
		super
	end

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

	def _g_update(arg)
		<<_html.chomp
<input type="text" name="#{my[:short_name]}" value="#{val}" class="#{_g_class arg}" />#{_g_errors arg}
_html
	end
	alias :_g_create :_g_update

	def val_cast(v)
		v.to_s
	end

end
