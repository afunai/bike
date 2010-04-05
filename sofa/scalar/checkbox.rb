# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Checkbox < Sofa::Field

	def initialize(meta = {})
		if meta[:tokens]
			meta[:options] ||= meta[:tokens] - ['mandatory']
			meta[:options] = ['_on'] if meta[:options].empty?
			meta[:mandatory] = meta[:tokens].include?('mandatory') && Array(meta[:options]).size > 1
		end
		if meta[:options].size == 1 && meta[:default] =~ /^(on|true|yes)$/i
			meta[:default] = meta[:options].first
		end
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
