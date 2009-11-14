# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Storage

	def self.instance(list)
		if folder = list.folder
			klass = Sofa::STORAGE[:klass].capitalize
			if klass == 'File' && folder != list[:parent]
				Temp.new list
			else
				self.const_get(klass).new list
			end
		else
			Temp.new list
		end
	end

	def initialize(list)
		@list = list
	end

	def select(conds = {})
		item_ids = _select(conds)
		item_ids = _sort(item_ids,conds)
		item_ids = _page(item_ids,conds)
	end

	def save(action,id,item)
		case action
			when :create
				store(:new_id,item.val)
			when :update
				store(item[:id],item.val)
				delete(id) if item[:id] != id
			when :delete
				delete(id)
		end
	end

	private

	def _select(conds)
		if conds[:id]
			_select_by_id(conds) | (@list.instance_variable_get(:@item_object).keys & conds[:id].to_a)
		elsif cid = (conds.keys - [:order,:p]).first
			m = "_select_by_#{cid}"
			respond_to?(m,true) ? __send__(m,conds) : []
		else
			_select_all(conds) | @list.instance_variable_get(:@item_object).keys
		end
	end

	def _sort(item_ids,conds)
		case conds[:order]
			when '-d','-id'
				item_ids.sort.reverse
			else
				item_ids.sort
		end
	end

	def _page(item_ids,conds)
		page = conds[:p].to_i
		page = 1 if page < 1
		size = @list[:p_size].to_i
		size = 10 if size < 1
		item_ids[(page - 1) * size,size].to_a
	end

def store(id,v)
end

def delete(id)
end

end
