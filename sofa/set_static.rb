# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'strscan'

class Sofa::Set::Static < Sofa::Field

	include Sofa::Set

	def initialize(meta = {})
		@meta = meta
		@meta.merge!(Sofa::Parser.parse_html meta[:html]) if meta[:html]
		@meta[:item] ||= {}
		@item_object = {}
	end

	def commit(type = :temp)
		items = pending_items
		items.each {|id,item| item.commit type }
		if valid?
			@result = (@action == :update) ? items : @action
			@action = nil if type == :persistent
			self
		end
	end

	private

	def _val
		inject({}) {|v,item|
			v[item[:id]] = item.val unless item.empty?
			v
		}
	end

	def _g_action_update(arg)
		(_get_by_action_tmpl(arg) || <<_html.chomp) if permit_get?(:action => :update)
<span><a href="#{_g_uri_update arg}">update</a></span>
_html
	end

	def _g_a_update(arg)
		if arg[:orig_action] != :read
			'<a>'
		elsif permit_get?(:action => :update)
			"<a href=\"#{_g_uri_update arg}\">"
		elsif permit? :delete
			"<a href=\"#{_g_uri_delete arg}\">"
		else
			'<a>'
		end
	end

	def _g_uri_update(arg)
		"#{my[:parent][:path]}/#{Sofa::Path::path_of :id => my[:id]}update.html"
	end

	def _g_uri_delete(arg)
		"#{my[:parent][:path]}/#{Sofa::Path::path_of :id => my[:id]}confirm_delete.html"
	end

	def _g_uri_detail(arg)
		"#{my[:parent][:path]}/#{Sofa::Path::path_of :id => my[:id]}read_detail.html"
	end

	def _g_hidden(arg)
		if arg[:orig_action] == :confirm
			action = my[:id][Sofa::REX::ID_NEW] ? :create : arg[:sub_action]
			<<_html.chomp
<input type="hidden" name="#{my[:short_name]}.action" value="#{action}" />
_html
		end
	end

	def permit_get?(arg)
		permit?(arg[:action]) || collect_item(arg[:conds] || {}).any? {|item|
			item.permit? arg[:action]
		}
	end

	def _post(action,v = {})
		each {|item|
			item_action = (item.action == :create) ? :update : action
			id = item[:id]
			if [:load_default,:delete].include?(item_action) || v.key?(id) || item(id).is_a?(Sofa::Meta)
				item.post(item_action,v[id])
			end
		}
		!pending_items.empty? || action == :delete
	end

	def collect_item(conds = {},&block)
		items = my[:item].keys
		items &= conds[:id].to_a if conds[:id] # select item(s) by id
		items.collect {|id|
			item = @item_object[id] ||= Sofa::Field.instance(
				my[:item][id].merge(:id => id,:parent => self)
			)
			block ? block.call(item) : item
		}
	end

	def val_cast(v)
		v.is_a?(::Hash) ? v : {:self => v}
	end

end
