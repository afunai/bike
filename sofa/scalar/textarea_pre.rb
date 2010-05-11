# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

require 'rack/utils'

class Sofa::Textarea::Pre < Sofa::Textarea

	def _g_default(arg)
		'<pre>' + Rack::Utils.escape_html(val.to_s) + '</pre>'
	end

end
