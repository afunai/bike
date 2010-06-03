# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Sofa::Set::Static::Folder

	private

	def _g_action_login(arg)
		if Sofa.client == 'nobody'
			<<_html
<div class="action_login"><a href="#{my[:dir]}/login.html">#{_ 'login...'}</a></div>
_html
		else
			<<_html
<div class="action_logout"><a href="#{my[:dir]}/logout.html?_token=#{Sofa.token}">#{_ 'logout'}</a></div>
_html
		end
	end

end
