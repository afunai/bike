# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Bike::Workflow::Attachment < Bike::Workflow

  DEFAULT_META = {
    :p_size     => 0,
    :item_label => Bike::I18n.n_('attachment', 'attachments', 1),
  }

  PERM = {
    :create => 0b00000,
    :read   => 0b00000,
    :update => 0b00000,
    :delete => 0b00000,
  }

  def permit?(roles, action)
    (action == :login) ||
    (@f[:parent] && @f[:parent].permit?(action))
  end

  def _get(arg)
    @f.instance_eval {
      if arg[:action] == :create || arg[:action] == :update
        new_item = item_instance '_001'

        item_outs = _g_default(arg) {|item, item_arg|
          action = item[:id][Bike::REX::ID_NEW] ? :create : :delete
          button_tmpl = my[:tmpl][:"submit_#{action}"] || <<_html.chomp
<input type="submit" name="@(short_name).action-#{action}" value="#{_ action.to_s}" />
_html
          button = item.send(:_get_by_tmpl, {}, button_tmpl)
          item_arg[:action] = :create if action == :create
          item_tmpl = item[:tmpl][:index].sub(/[\w\W]*\$\(.*?\)/, "\\&#{button}")
          item.send(:_get_by_tmpl, item_arg, item_tmpl)
        }
        tmpl = my[:tmpl][:index].gsub('$()', item_outs)
        _get_by_tmpl({:p_action => arg[:p_action], :action => :update}, tmpl)
      end
    }
  end

  def _hide?(arg)
    arg[:action] == :submit
  end

end
