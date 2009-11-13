# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Set::Dynamic < Sofa::Field

	include Sofa::Set

	REX_NEW_ID = /^_\d/

	attr_reader :storage

	def initialize(meta = {})
		@meta = meta
		@storage = Sofa::Storage.instance self
		@item_object = {}
	end

	private

	def _val
		@storage.val
	end

	def _get(arg)
		collect_item(arg[:conds] || {}) {|item|
			item.get arg
		}
	end

	def _post(action,v = nil)
		if action == :update && v.is_a?(::Hash)
			v.each_key {|id|
				item = item_instance id
				item_action = id[REX_NEW_ID] ? :create : (v[id][:delete] ? :delete : :update)
				item.post(item_action,v[id])
			}
		else
			@storage.post(action,v) # create / delete
		end
	end

	def collect_item(conds = {},&block)
		@storage.select(conds).collect {|id|
			item = item_instance id
			block ? block.call(item) : item
		}
	end

def item_instance(id)
	unless @item_object[id]
		@item_object[id] = Sofa::Field.instance(
			:id     => id,
			:parent => self,
			:klass  => 'set-static',
			:html   => my[:set_html]
		)
		id[REX_NEW_ID] ? @item_object[id].load_default : @item_object[id].load(@storage.val id)
	end
	@item_object[id]
end

end
