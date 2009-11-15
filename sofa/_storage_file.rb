# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Storage::File < Sofa::Storage

	def self.available?
		Sofa::STORAGE['File'] && Sofa::STORAGE['File']['data_dir']
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
		glob conds[:id].to_a
	end

	def _select_by_d(conds)
	end

	def _select_all(conds)
		glob
	end

	def store(id,v)
		id = new_id if id == :new_id
	end

	def new_id
		'%.4d' % (@val.keys.max.to_i + 1)
	end

	def delete(id)
	end

	def glob(id = [])
		prefix = '' # @sd[:name].sub(/^main-/,'')
		id_pattern   = id.empty? ? '[0-9]*_[0-9]*' : "{#{id.join ','}}"
		glob_pattern = "#{prefix}#{id_pattern}.yaml"
		::Dir.chdir(Sofa::STORAGE['File']['data_dir'] + @dir) {
			::Dir.glob(glob_pattern).collect {|f| f[/\d{8}_\d{4,}/] }
		}
	end

end
