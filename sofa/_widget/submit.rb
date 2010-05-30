# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Sofa::Set::Dynamic

	private

	def _g_submit(arg)
		<<_html
<div class="submit">
#{_g_submit_commit arg}#{_g_submit_confirm arg}#{_g_submit_confirm_delete arg}</div>
_html
	end

	def _g_submit_commit(arg)
		if collect_item(arg[:conds]).all? {|i| i[:id] =~ Sofa::REX::ID_NEW }
			action = :create
		elsif arg[:orig_action] == :confirm
			action = arg[:sub_action]
		else
			action = arg[:orig_action]
		end
		<<_html unless my[:confirm] == :mandatory && arg[:orig_action] != :confirm
	<input name="#{my[:short_name]}.status-public" type="submit" value="#{_ action.to_s}" />
_html
	end

	def _g_submit_confirm(arg)
		label = _ 'confirm'
		<<_html if my[:confirm] && arg[:orig_action] != :confirm
	<input name="#{my[:short_name]}.action-confirm_#{arg[:orig_action]}" type="submit" value="#{label}" />
_html
	end

	def _g_submit_confirm_delete(arg)
		if (
			permit_get?(arg.merge :action => :delete) &&
			collect_item(arg[:conds]).find {|item| item[:id] !~ Sofa::REX::ID_NEW } &&
			arg[:orig_action] != :confirm
		)
			<<_html
	<input name="#{my[:short_name]}.action-confirm_delete" type="submit" value="#{_ 'delete...'}" />
_html
		end
	end

end
