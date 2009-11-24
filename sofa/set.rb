# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

module Sofa::Set

	include Enumerable

	def val(*steps)
		if steps.empty?
			_val
		elsif i = item(steps)
			i.val
		end
	end

	def item(*item_steps)
		item_steps = item_steps.first if item_steps.first.is_a? ::Array
		return self if item_steps.empty?

		id,*item_steps = item_steps

		if id.is_a?(::String) && child = collect_item(:id => id).first
			item = item_steps.empty? ? child : child.item(*item_steps)
			block_given? ? yield(item) : item
		end
	end

	def pending?
		!pending_items.empty? || action
	end

def errors
	errors = {}
	@item_object.each_pair {|id,item|
		errors[id] = item.errors if item.errors
	}
	errors unless errors.empty?
end

	def collect(&block)
		collect_item({},&block)
	end

	def each(&block)
		collect_item.each &block
	end

	private

	def _get(arg)
		if respond_to?("_get_#{arg[:action]}",true)
			__send__("_get_#{arg[:action]}",arg)
		else
			_get_by_tmpl(arg,my[:tmpl])
		end
	end

	def _get_by_method(arg)
		collect_item(arg[:conds] || {}) {|item|
			item_arg = arg[item[:id]] || {}
			item_arg[:action] ||= arg[:action]
			item.get item_arg
		}
	end

	def permit_get?(arg)
		permit?(arg[:action]) || collect_item(arg[:conds] || {}).any? {|item|
			item.permit? arg[:action]
		}
	end

	def permit_post?(action,val)
		(action != :update) || val.all? {|id,v|
			case id
				when Sofa::Set::Dynamic::REX_NEW_ID
					action = :create
				when Sofa::Storage::REX_ID
					action = v['_action'] ? v['_action'].intern : :update
				when /^_submit/
					next true # not a item value
			end
			permit?(action) || (action != :create && item(id) && item(id).permit?(action))
		}
	end

	def pending_items
		@item_object.keys.sort.inject({}) {|h,id|
			h[id] = @item_object[id] if @item_object[id].pending?
			h
		}
	end

end
