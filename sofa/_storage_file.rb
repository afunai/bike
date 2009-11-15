# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Storage::File < Sofa::Storage

	def self.available?
		Sofa::STORAGE['File'] && Sofa::STORAGE['File']['data_dir']
false
	end

	def initialize(sd)
		super
		@dir = @sd[:folder][:dir]
	end

	def val(id = nil)
		{}
	end

	private

	def _select_by_id(conds)
		val.keys & conds[:id].to_a
[@dir]
	end

	def _select_by_d(conds)
	end

	def _select_all(conds)
		val.keys
	end

	def store(id,v)
		id = new_id if id == :new_id
	end

	def new_id
		'%.4d' % (@val.keys.max.to_i + 1)
	end

	def delete(id)
	end

end
