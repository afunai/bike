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

	private

end

__END__

	def self.instance(list)
		f = list
		until f.nil? || f.is_a? Sofa::Set::Folder
			f = f[:parent]
		end
	end

