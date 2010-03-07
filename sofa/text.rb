# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Text < Sofa::Field

	def initialize(meta = {})
		meta[:size] = $&.to_i if meta[:tokens] && meta[:tokens].first =~ /^\d+$/
		super
	end

	def errors
		if (my[:max].to_i > 0) && (val.to_s.size > my[:max])
			['too long']
		else
			[]
		end
	end

	private

	def _g_update(arg)
		<<_html.chomp
<input type="text" name="#{my[:short_name]}" value="#{val}" />#{_g_errors}
_html
	end
	alias :_g_create :_g_update

	def _g_errors(arg = {})
		errors.first
	end

end
