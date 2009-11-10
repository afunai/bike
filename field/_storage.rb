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
	base_entries = _select(conds)
	base_entries = _sort(conds,base_entries)
	base_entries = _paginate(conds,base_entries)
end

def _select(conds)
	if conds[:id]
		_select_by_id(conds) | (list.queue.keys & conds[:id])
	elsif conds[:q]
		_select_by_q(conds)
	elsif conds[:d] || conds[:y]
		_select_by_d(conds)
	else
		_select_all(conds) | list.queue.keys
	end
end

def load(id) #=> item
end

def save(orig_id,item)
end

def delete(id)
end

if nil
def list.commit(type = :all)
	if @storage.is_a? Sofa::Storage::Val
		queue.each {|id,item| item.commit(:val) && @storage.save(id,item) }
	elsif type == :all
		queue.each {|id,item| item.commit(:val) && @storage.save(id,item) && item.commit(:all) }
	end
end
end

	private

end

__END__

	def self.instance(list)
		f = list
		until f.nil? || f.is_a? Sofa::Set::Folder
			f = f[:parent]
		end
	end

