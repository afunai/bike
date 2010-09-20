# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Bike::Set::Static::Folder

  private

  def _g_me(arg)
    if Bike.client == 'nobody'
      <<_html
<div class="me">
  #{_g_action_login arg}</div>
_html
    else
      img   = Bike::Set::Static::Folder.root.item('_users', 'main', Bike.client, 'avatar')
      roles = Bike::Workflow.roles my[:roles]
      <<_html
<div class="me">
  <a href="#{Bike.uri}/_users/id=#{Bike.client}/update.html">
    #{img.send(:_get_by_self_reference, :sub_action => :without_link) if img}
  </a>
  <div class="client">#{Bike.client}</div>
  <div class="roles">(#{roles.join ', '})</div>
  #{_g_action_login arg}</div>
_html
    end
  end

end
