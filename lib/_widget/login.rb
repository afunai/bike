# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Runo::Set::Dynamic

  private

  def _g_login(arg)
    path = Runo::Path.path_of arg[:conds]
    action = arg[:dest_action]
    <<_html
<form id="form_#{my[:name]}" method="post" action="#{my[:base_path]}/#{path}login.html">
  <div class="login">
    <input type="hidden" name="dest_action" value="#{action}" />
    <label for="login_id">#{_ 'ID'}</label><input type="text" id="login_id" name="id" size="10" value="" />
    <label for="login_pw">#{_ 'Password'}</label><input type="password" id="login_pw" name="pw" size="10" value="" />
    <input type="submit" value="#{_ 'login'}" />
  </div>
</form>
_html
  end

end
