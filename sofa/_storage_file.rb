# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'rubygems'
require 'yaml'

require 'ya2yaml'

class Sofa::Storage::File < Sofa::Storage

	REX_ID = /\d{8}_\d{4,}/

	def self.available?
		Sofa::STORAGE['File'] && Sofa::STORAGE['File']['data_dir']
	end

	def initialize(sd)
		super
		@dir = Sofa::STORAGE['File']['data_dir'] + @sd[:folder][:dir]
	end

	def val(id = nil)
		if id
			v = raw_load id
			YAML.load(v) if v
		else
			{} # too many to return
		end
	end

	private

	def _select_by_id(conds)
		glob(conds[:id].to_a).collect {|f| f[REX_ID] }
	end

	def _select_by_d(conds)
	end

	def _select_all(conds)
		glob.collect {|f| f[REX_ID] }
	end

	def store(id,v)
		id = new_id if id == :new_id
	end

	def new_id
		'%.4d' % (@val.keys.max.to_i + 1)
	end

	def delete(id)
	end

	def glob(id = :all)
		return [] if id == []

		prefix       = (@sd[:name] == 'main') ? '' : @sd[:name].sub(/^main-/,'') + '_'
		id_pattern   = (id == :all) ? '[0-9]*_[0-9]*' : "{#{id.join ','}}"
		glob_pattern = "#{prefix}#{id_pattern}.yaml"
		::Dir.chdir(@dir) { ::Dir.glob glob_pattern }
	end

	def raw_load(id)
		v = nil
		file = glob(id.to_a).first
		::File.open(::File.join(@dir,file),'r') {|f|
			f.flock ::File::LOCK_SH
			v = f.read
			f.flock ::File::LOCK_UN
		} if file
		v
	end

def raw_save(path,v)
	dig_dir(path)
	file = file_from_path(path)

	::File.open(file,'w') {|f|
		f.flock(::File::LOCK_EX)
		f.truncate(0)
		f << v
		f.flock(::File::LOCK_UN)
		f.chmod(0664) rescue nil
	}
end

end
