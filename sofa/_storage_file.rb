# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'rubygems'
require 'yaml'
require 'ya2yaml'

class Sofa::Storage::File < Sofa::Storage

	def self.available?
		Sofa['STORAGE']['File'] && Sofa['STORAGE']['File']['data_dir']
	end

	def initialize(sd)
		super
		@dir = Sofa['STORAGE']['File']['data_dir'] + @sd[:folder][:dir]
	end

	def val(id = nil)
		if id
			load_yaml id
		else
			# this could be HUGE.
			_select_all({}).inject({}) {|v,id|
				v[id] = load_yaml id
				v
			}
		end
	end

	def build(v)
		clear
		v.each {|id,v| store(id,v) }
		self
	end

	def clear
		glob.each {|file| ::File.unlink ::File.join(@dir,file) }
		self
	end

	def store(id,v)
		save_yaml(id,v)
	end

	def delete(id)
		remove_file(id) && id
	end

	private

	def _select_by_id(conds)
		glob(conds[:id].to_a).collect {|f| f[Sofa::REX::ID] }.compact
	end

	def _select_by_d(conds)
		glob(conds[:d].to_s).collect {|f| f[Sofa::REX::ID] }.compact
	end

	def _select_all(conds)
		glob.collect {|f| f[Sofa::REX::ID] }.compact
	end

	def glob(id = :all)
		glob_pattern = "#{file_prefix}#{pattern_for id}.yaml"
		::Dir.chdir(@dir) { ::Dir.glob glob_pattern }
	end

	def file_prefix
		(@sd[:name] == 'main') ? '' : @sd[:name].sub(/^main-/,'') + '_'
	end

	def pattern_for(id)
		if id.is_a? Array
			"{#{cast_ids(id).join ','}}"
		elsif id == :all
			'[0-9]*_*'
		elsif id =~ /\A\d{4,8}\z/
			"#{id}*"
		end
	end

	def load_yaml(id)
		v = nil
		file = glob(id.to_a).first
		::File.open(::File.join(@dir,file),'r') {|f|
			f.flock ::File::LOCK_SH
			v = f.read
			f.flock ::File::LOCK_UN
		} if file
		YAML.load(v) if v
	end

	def save_yaml(id,v)
		new_id = false
		if id == :new_id
			id = new_id(v)
			new_id = true
		end

		file = "#{file_prefix}#{id}.yaml"
		::File.open(::File.join(@dir,file),'a') {|f|
			break if new_id && f.pos != 0 # duplicate id

			f.flock ::File::LOCK_EX
			f.seek 0
			f.truncate 0
			f << v.ya2yaml(:syck_compatible => true)
			f.flock ::File::LOCK_UN
			f.chmod 0664
		} && id
	end

	def remove_file(id)
		glob(id.to_a) .each {|file|
			::File.unlink ::File.join(@dir,file) # may include child files
		}
	end

end
