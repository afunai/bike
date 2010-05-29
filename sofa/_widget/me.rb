# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Sofa::Set::Static::Folder

	private

	def _g_me(arg)
		if Sofa.client == 'nobody'
			<<_html
<div class="me">
	#{_g_action_login arg}</div>
_html
		else
			img = Sofa::Set::Static::Folder.root.item('_users','main',Sofa.client,'avatar')
			<<_html
<div class="me">
	<a href="#{Sofa.base[:uri] if Sofa.base}/_users/id=#{Sofa.client}/update.html">
		#{img.send(:_get_by_self_reference,:action => 'thumbnail') if img}
	</a>
	<div class="client">#{Sofa.client}</div>
	#{_g_action_login arg}</div>
_html
		end
	end

end
