# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Workflow::Attachment < Sofa::Workflow

	DEFAULT_META = {
		:p_size     => 0,
		:item_label => Sofa::I18n.n_('attachment','attachments',1),
	}

	PERM = {
		:create => 0b0000,
		:read   => 0b0000,
		:update => 0b0000,
		:delete => 0b0000,
	}

	def permit?(roles,action)
		(action == :login) ||
		(@sd[:parent] && @sd[:parent].permit?(action))
	end

	def _get(arg)
		@sd.instance_eval {
			if arg[:action] == :create || arg[:action] == :update
				new_item = item_instance '_001'

				item_outs = _g_default(arg) {|item,item_arg|
					action = item[:id][Sofa::REX::ID_NEW] ? :create : :delete
					button_tmpl = my["tmpl_submit_#{action}".intern] || <<_html.chomp
<input type="submit" name="@(short_name).action-#{action}" value="#{_ action.to_s}">
_html
					button = item.send(:_get_by_tmpl,{},button_tmpl)
					item_arg[:action] = :create if action == :create
					item_tmpl = item[:tmpl].sub(/[\w\W]*\$\(.*?\)/,"\\&#{button}")
					item.send(:_get_by_tmpl,item_arg,item_tmpl)
				}
				tmpl = my[:tmpl].gsub('$()',item_outs.join)
				_get_by_tmpl({:p_action => arg[:p_action],:action => :update},tmpl)
			end
		}
	end

	def _hide?(arg)
		arg[:action] == :submit
	end

end
