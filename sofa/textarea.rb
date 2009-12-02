# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Textarea < Sofa::Field

	private

	def _get_create(arg)
		<<_html
<textarea name="#{my[:name]}" cols="#{my[:width]}" rows="#{my[:height]}">#{val}</textarea>
_html
	end
	alias :_get_update :_get_create

end


class Sofa::Textarea::Pre < Sofa::Textarea

	def _get_read(arg)
		'<pre>' + Rack::Utils.escape_html(val.to_s) + '</pre>'
	end

end
