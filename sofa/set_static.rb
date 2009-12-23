# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'strscan'

class Sofa::Set::Static < Sofa::Field

	include Sofa::Set

	DEFAULT_ITEMS = {
		'_owner'   => {:klass => 'meta-owner'},
		'_group'   => {:klass => 'meta-group'},
		'_status'  => {:klass => 'text'},
		'_updated' => {:klass => 'text'},
	}

	def initialize(meta = {})
		@meta = meta
		@meta.merge!(Sofa::Parser.parse_html meta[:html]) if meta[:html]
		@meta[:item] ||= {}
		@meta[:item].merge! self.class.const_get(:DEFAULT_ITEMS)
		@item_object = {}
	end

	def commit(type = :temp)
		items = pending_items
		items.each {|id,item| item.commit type }
		if pending_items.empty?
			@result = (@action == :update) ? items : @action
			@action = nil
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
		<<_html.chomp
<span><a href="#{_g_uri_update arg}">update</a></span>
_html
	end

	def _g_uri_update(arg)
		"#{my[:parent][:path]}/id=#{my[:id]}/update.html" if my[:parent].is_a? Sofa::Set::Dynamic
	end

	def _post(action,v = {})
		each {|item|
			id = item[:id]
			item.post(action,v[id]) if action == :load_default || v.has_key?(id)
		}
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
