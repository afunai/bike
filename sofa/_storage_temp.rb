# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Storage::Temp < Sofa::Storage

	def self.available?
		true
	end

	def persistent?
		false
	end

	def val(id = nil)
		@val ||= {}
		id ? @val[id] : @val
	end

	def build(v)
		@val = v
		self
	end

	def clear
		@val = {}
		self
	end

	def store(id,v,ext = :unused)
		if new_id?(id,v)
			old_id = id
			id = new_id v
			return nil if @val && @val[id]
		end
		val[id] = v
		id
	end

	def delete(id)
		@val.delete id
		id
	end

	def move(old_id,new_id)
		rex = /\A#{old_id}/
		val.keys.each {|id|
			if id =~ rex
				to_id = id.sub(rex,new_id)
				@val[to_id] = @val.delete id
			end
		}
		new_id
	end

	private

	def _select_by_id(conds)
		val.keys & conds[:id].to_a
	end

	def _select_by_d(conds)
		rex_d = /^#{conds[:d]}/
		val.keys.select {|id| id[rex_d] }
	end

	def _select_all(conds)
		val.keys
	end

end
