# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Runo::Set::Dynamic

  private

  def _g_action_create(arg)
    label = _('create new %{item}...') % {
      :item => _((my[:item].size == 1 && my[:item]['default'][:label]) || my[:item_label])
    }
    (_get_by_action_tmpl(arg) || <<_html) if permit? :create
<div class="action_create"><a href="#{_g_uri_create arg}">#{label}</a></div>
_html
  end

  def _g_uri_create(arg)
    "#{my[:path]}/create.html"
  end

end
