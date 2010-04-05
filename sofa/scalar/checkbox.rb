# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Checkbox < Sofa::Field

	def initialize(meta = {})
		meta[:mandatory] = (meta[:tokens] && meta[:tokens].include?('mandatory'))
		super
	end

	def errors
		if val.empty?
			my[:mandatory] ? ['mandatory'] : []
		else
			(val - my[:options]).empty? ? [] : ['no such option']
		end
	end

	private

	def _g_default(arg)
		val.join ', '
	end

	def _g_update(arg)
		options = my[:options].collect {|opt|
			checked = (val.include? opt) ? ' checked' : ''
			<<_html
<span class="#{_g_class arg}">
	<input type="checkbox" id="#{my[:short_name]}-#{opt}" name="#{my[:short_name]}[]" value="#{opt}"#{checked} />
	<label for="#{my[:short_name]}-#{opt}">#{opt}</label>
</span>
_html
		}.join
		<<_html.rstrip
<input type="hidden" name="#{my[:short_name]}[]" value="" />
#{options}#{_g_errors arg}
_html
	end
	alias :_g_create :_g_update

	def _g_class(arg)
		out = super
		out ? "checkbox #{out}" : 'checkbox'
	end

	def val_cast(v)
		Array(v).collect {|i|
			i.to_s unless i.to_s.empty?
		}.compact
	end

end
