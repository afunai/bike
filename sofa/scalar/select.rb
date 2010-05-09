# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Select < Sofa::Field

	def initialize(meta = {})
		meta[:mandatory] = (meta[:tokens] && meta[:tokens].include?('mandatory'))
		super
	end

	def errors
		if my[:mandatory] && val.empty?
			[_ 'mandatory']
		elsif my[:options].include?(val) || val.empty?
			[]
		else
			[_ 'no such option']
		end
	end

	private

	def _g_update(arg)
		options = my[:options].collect {|opt|
			selected = (opt == val) ? ' selected' : ''
			"\t<option#{selected}>#{opt}</option>\n"
		}.join
		unless my[:mandatory] && my[:options].include?(val)
			options = "\t<option value=\"\">#{_ 'please select'}</option>\n#{options}"
		end
		<<_html.chomp
<select name="#{my[:short_name]}" class="#{_g_class arg}">
#{options}</select>#{_g_errors arg}
_html
	end
	alias :_g_create :_g_update

	def val_cast(v)
		v.to_s
	end

end
