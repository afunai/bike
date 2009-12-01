# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Text < Sofa::Field

	def initialize(meta = {})
		meta[:size] = $&.to_i if meta[:tokens] && meta[:tokens].first =~ /^\d+$/
		super
	end

	private

	def _get_update(arg)
		<<_html.chomp
<input type="text" id="#{my[:name]}" value="#{val}" />
_html
	end

end
