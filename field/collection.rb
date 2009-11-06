# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

module Sofa::Field::Collection

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

	if id.is_a?(::String) && child = collect_item(id).first
		item = item_steps.empty? ? child : child.item(*item_steps)
		block_given? ? yield(item) : item
	end
end

def errors
	errors = {}
	@item_object.each_pair {|id,item|
		errors[id] = item.errors if item.errors
	}
	errors unless errors.empty?
end

def collect(&block)
	collect_item(:all,&block)
end

def each(&block)
	collect_item(:all).each &block
end

end


__END__

	def modified?
		(!queue.empty? || @queue) ? true : false
	end

	def queue
		@item_object.keys.inject({}) {|h,id|
			h[id] = @item_object[id] if @item_object[id].modified?
			h
		}
	end

	def errors
		errors = {}
		@item_object.each_pair {|id,item|
			errors[id] = item.errors if item.errors
		}
		errors unless errors.empty?
	end


	def commit(option = {})
		return self unless modified?

		if valid?
			if persistent? || option[:item_steps] || !my[:parent]
				option[:item_steps] ||= []
				item = item(option[:item_steps].shift) if option[:item_steps].first
				q    = item ? {item[:id] => item} : queue()
				@result = _commit(q,option)
				@queue  = nil # for create/delete
			else
				persistent_commit
			end
		else
			@result = {}
		end
		self
	end

	def collect(&block)
		collect_item(:all,&block)
	end

	def each(&block)
		collect_item(:all).each &block
	end

	def traverse(item = self,&block)
		base = self
		name = item[:full_name][/^#{base[:full_name]}-(.+)/,1]
		result = block_given? ? yield(name,item) : item
		if item.is_a?(Field::Collection) && result != :skip
			[
				result,
				item.collect {|sub_item| base.traverse(sub_item,&block) }
			]
		else
			result
		end
	end

