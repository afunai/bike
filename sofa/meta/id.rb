# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Sofa::Meta::Id < Sofa::Field

	# not include Sofa::Meta as this is SHORT_ID, not a full id.

	def initialize(meta = {})
		meta[:size] = $&.to_i if meta[:tokens] && meta[:tokens].first =~ /^\d+$/
		super
	end

	def errors
		if (my[:max].to_i > 0) && (val.size > my[:max])
			[_('too long: %{max} characters maximum') % {:max => my[:max]}]
		elsif (my[:min].to_i == 1) && val.empty?
			[_ 'mandatory']
		elsif (my[:min].to_i > 0) && (val.size < my[:min])
			[_('too short: %{min} characters minimum') % {:min => my[:min]}]
		elsif val !~ /\A#{Sofa::REX::ID_SHORT}\z/
			[_('malformatted id')]
		else
			[]
		end
	end

	private

	def _g_create(arg)
		<<_html.chomp
<input type="text" name="#{my[:short_name]}" value="#{val}" size="#{my[:size]}" class="#{_g_class arg}" />#{_g_errors arg}
_html
	end

	def _post(action,v)
		if action == :load || (action == :create && @val.empty?)
			@val = val_cast v
		end
	end

	def val_cast(v)
		v.to_s
	end

end