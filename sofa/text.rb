# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Text < Sofa::Field

	def initialize(meta = {})
		meta[:size] = $&.to_i if meta[:tokens] && meta[:tokens].first =~ /^\d+$/
		super
	end

	private

	def _g_update(arg)
		<<_html.chomp
<input type="text" name="#{my[:short_name]}" value="#{val}" />
_html
	end
	alias :_g_create :_g_update

end
