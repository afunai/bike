# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Sofa::Set::Dynamic

	private

	def _g_login(arg)
		path = Sofa::Path.path_of arg[:conds]
		action = arg[:dest_action]
		<<_html
<form id="#{my[:name]}" method="post" action="#{my[:base_path]}/#{path}login.html">
	<input type="hidden" name="dest_action" value="#{action}" />
	<label for="id">id</label><input type="text" id="id" name="id" size="10" value="" />
	<label for="pw">pw</label><input type="password" id="pw" name="pw" size="10" value="" />
	<input type="submit" value="#{_ 'login'}" />
</form>
_html
	end

end