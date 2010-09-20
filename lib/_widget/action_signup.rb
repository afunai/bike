# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Bike::Set::Static::Folder

  private

  def _g_action_signup(arg)
    (_get_by_action_tmpl(arg) || <<_html) if Bike.client == 'nobody'
<div class="action_signup"><a href="/_users/create.html">#{_ 'signup'}</a></div>
_html
  end

end
