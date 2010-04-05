# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Radio < Sofa::Field

	def initialize(meta = {})
		meta[:mandatory] = (meta[:tokens] && meta[:tokens].include?('mandatory'))
		super
	end

	def errors
		if val.empty?
			my[:mandatory] ? ['mandatory'] : []
		else
			my[:options].include?(val) ? [] : ['no such option']
		end
	end

	private

	def _g_update(arg)
		options = my[:options].collect {|opt|
			checked = (opt == val) ? ' checked' : ''
			<<_html
<span class="#{_g_class arg}">
	<input type="radio" id="#{my[:short_name]}-#{opt}" name="#{my[:short_name]}" value="#{opt}"#{checked} />
	<label for="#{my[:short_name]}-#{opt}">#{opt}</label>
</span>
_html
		}.join
		<<_html.rstrip
<input type="hidden" name="#{my[:short_name]}" value="" />
#{options}#{_g_errors arg}
_html
	end
	alias :_g_create :_g_update

	def _g_class(arg)
		out = super
		out ? "radio #{out}" : 'radio'
	end

	def val_cast(v)
		v.to_s
	end

end
