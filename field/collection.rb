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
