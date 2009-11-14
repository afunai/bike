# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Storage::Temp < Sofa::Storage

	def initialize(list)
		super
		@val = {} # the 'storage'.
	end

	def val(id = nil)
		id ? @val[id] : @val
	end

	def load(v)
		@val = v
	end

	private

	def _select_by_id(conds)
		val.keys & conds[:id].to_a
	end

	def _select_by_q(conds)
	end

	def _select_by_d(conds)
	end

	def _select_all(conds)
		val.keys
	end

	def store(id,v)
		id = new_id if id == :new_id
		@val[id] = v
	end

	def new_id
		'%.4d' % (@val.keys.max.to_i + 1)
	end

	def delete(id)
		@val.delete id
	end

end
