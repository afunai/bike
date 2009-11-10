# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Storage

	def self.instance(list)
		if folder = list.folder
			klass = Sofa::STORAGE[:klass].capitalize
			if klass == 'File' && folder != list[:parent]
				Val.new list
			else
				self.const_get(klass).new list
			end
		else
			Val.new list
		end
	end

	def initialize(list)
		@list = list
	end

	def select(conds = {})
		entries = _select(conds)
		entries = _sort(conds,entries)
		entries = _paginate(conds,entries)
	end

def save(orig_id,item)
end

def delete(id)
end

	private

	def _select(conds)
		if conds[:id]
			_select_by_id(conds) | (@list.instance_variable_get(:@item_object).keys & conds[:id].to_a)
		elsif conds[:q]
			_select_by_q(conds)
		elsif conds[:d] || conds[:y]
			_select_by_d(conds)
		else
			_select_all(conds) | @list.instance_variable_get(:@item_object).keys
		end
	end

	def _sort(conds,entries)
		entries
	end

	def _paginate(conds,entries)
		entries
	end

end

__END__

def Field.commit
	f = self
	f = f[:parent] until f.nil? || f.persistent?
	f ? f._commit(:all) : self._commit(:all)
end

def Field._commit(type)
	@queue = nil if valid?
end
def Set._commit(type)
	queue.each {|id,item| item._commit(:val) }
end
def List._commit(type)
	if @storage.is_a? Sofa::Storage::Val
		queue.each {|id,item| item._commit(:val) && @storage.save(id,item) }
	elsif type == :all
		queue.each {|id,item| item._commit(:val) && @storage.save(id,item) && item._commit(:all) }
	end
end

	def self.instance(list)
		f = list
		until f.nil? || f.is_a? Sofa::Set::Folder
			f = f[:parent]
		end
	end

