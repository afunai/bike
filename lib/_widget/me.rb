# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Runo::Set::Static::Folder

  private

  def _g_me(arg)
    if Runo.client == 'nobody'
      <<_html
<div class="me">
  #{_g_action_login arg}</div>
_html
    else
      img = Runo::Set::Static::Folder.root.item('_users', 'main', Runo.client, 'avatar')
      <<_html
<div class="me">
  <a href="#{Runo.base[:uri] if Runo.base}/_users/id=#{Runo.client}/update.html">
    #{img.send(:_get_by_self_reference, :sub_action => :without_link) if img}
  </a>
  <div class="client">#{Runo.client}</div>
  #{_g_action_login arg}</div>
_html
    end
  end

end
