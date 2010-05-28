# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Sofa::Set::Static

	private

	def _g_action_update(arg)
		(_get_by_action_tmpl(arg) || <<_html.chomp) if permit_get?(:action => :update)
<div class="action_update"><a href="#{_g_uri_update arg}">#{_ 'update...'}</a></div>
_html
	end

end
