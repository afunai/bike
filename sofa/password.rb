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
<input type="password" name="#{my[:short_name]}" value="" />
_html
	end
	alias :_g_create :_g_update

	def _post(action,v)
		case action
			when :load
				@val = v
			when :create,:update
				salt = ('a'..'z').to_a[rand 26] + ('a'..'z').to_a[rand 26]
				@val = v.crypt salt
		end
	end

end
