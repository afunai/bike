# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Sofa::Set::Dynamic

	private

	def _g_submit(arg)
		<<_html
<div class="submit">
#{_g_submit_commit arg}#{_g_submit_preview arg}#{_g_submit_preview_delete arg}</div>
_html
	end

	def _g_submit_commit(arg)
		if collect_item(arg[:conds]).all? {|i| i[:id] =~ Sofa::REX::ID_NEW }
			action = :create
		elsif arg[:orig_action] == :preview
			action = arg[:sub_action]
		else
			action = arg[:orig_action]
		end
		<<_html unless my[:preview] == :mandatory && arg[:orig_action] != :preview
	<input name="#{my[:short_name]}.status-public" type="submit" value="#{_ action.to_s}" />
_html
	end

	def _g_submit_preview(arg)
		label = _ 'preview'
		<<_html if my[:preview] && arg[:orig_action] != :preview
	<input name="#{my[:short_name]}.action-preview_#{arg[:orig_action]}" type="submit" value="#{label}" />
_html
	end

	def _g_submit_preview_delete(arg)
		if (
			permit_get?(arg.merge :action => :delete) &&
			collect_item(arg[:conds]).find {|item| item[:id] !~ Sofa::REX::ID_NEW } &&
			arg[:orig_action] != :preview
		)
			<<_html
	<input name="#{my[:short_name]}.action-preview_delete" type="submit" value="#{_ 'delete...'}" />
_html
		end
	end

end
