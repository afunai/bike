# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Password < Sofa::Field

	def initialize(meta = {})
		meta[:size] = $&.to_i if meta[:tokens] && meta[:tokens].first =~ /^\d+$/
		super
	end

	private

	def _g_default(arg)
		'xxxxx'
	end

	def _g_update(arg)
		<<_html.chomp
<input type="password" name="#{my[:short_name]}" value="" class="#{_g_class arg}" />#{_g_errors arg}
_html
	end
	alias :_g_create :_g_update

	def _post(action,v)
		case action
			when :load
				@size = nil
				@val = v
			when :create,:update
				if v.is_a?(::String) && !v.empty?
					salt = ('a'..'z').to_a[rand 26] + ('a'..'z').to_a[rand 26]
					@size = v.size
					@val = v.crypt salt
				elsif @val.nil?
					@size = 0
				else
					# no action: keep current @val
				end
		end
	end

end
