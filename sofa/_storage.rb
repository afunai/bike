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

def save(id,v) # do not include move action.
end

def delete(id)
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

end

__END__

def Field.commit
	f = self
	f = f[:parent] until f.nil? || f.persistent?
	f ? f._commit(:persistent) : self._commit(:persistent)
end

def Field._commit(type)
	@queue = nil if valid?
end
def Set._commit(type)
	queue.each {|id,item| item._commit(:temp) }
end
def List._commit(type)
	if @storage.is_a? Sofa::Storage::Temp
		queue.each {|id,item| item._commit(type) }
	elsif type == :persistent
		queue.each {|id,item| item._commit(:temp) && @storage.save(id,item) && item._commit(:persistent) }
	end
end

	def self.instance(list)
		f = list
		until f.nil? || f.is_a? Sofa::Set::Folder
			f = f[:parent]
		end
	end

