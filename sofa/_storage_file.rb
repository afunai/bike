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
			load id
		else
			# this could be HUGE.
			_select_all({}).inject({}) {|v,id|
				v[id] = load id
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

	def store(id,v,ext = nil)
		save(id,v,ext)
	end

	def delete(id)
		remove_file(id) && id
	end

	private

	def _select_by_id(conds)
		glob(conds[:id].to_a).collect {|f| f[/\d.*/][Sofa::REX::ID] }.compact
	end

	def _select_by_d(conds)
		glob(conds[:d].to_s).collect {|f| f[/\.yaml$/] && f[/\d.*/][Sofa::REX::ID] }.compact
	end

	def _select_all(conds)
		glob.collect {|f| f[/\.yaml$/] && f[/\d.*/][Sofa::REX::ID] }.compact
	end

	def glob(id = :all)
		glob_pattern = "#{file_prefix}#{pattern_for id}.[a-z]*"
		::Dir.chdir(@dir) { ::Dir.glob glob_pattern }
	end

	def file_prefix
		(@sd[:name] == 'main') ? '' : @sd[:name].sub(/^main-/,'') + '_'
	end

	def pattern_for(id)
		if id.is_a? Array
			"{#{id.join ','}}"
		elsif id == :all
			'[0-9]*_*'
		elsif id =~ /\A\d{4,8}\z/
			"#{id}*"
		end
	end

	def load(id)
		v = nil
		file = glob(id.to_a).sort.first
		::File.open(::File.join(@dir,file),'r') {|f|
			f.flock ::File::LOCK_SH
			v = f.read
			f.flock ::File::LOCK_UN
		} if file
		(file[/\.yaml$/] ? YAML.load(v) : v) if v
	end

	def save(id,v,ext)
		if id == :new_id
			id = new_id(v)
			new_id = true
		end

		if ext
			val = v
			ext = 'y' if ext == 'yaml'
			remove_file id
		else
			val = v.ya2yaml(:syck_compatible => true)
			ext = 'yaml'
		end

		file = "#{file_prefix}#{id}.#{ext}"
		::File.open(::File.join(@dir,file),'a') {|f|
			break if new_id && f.pos != 0 # duplicate id

			f.flock ::File::LOCK_EX
			f.seek 0
			f.truncate 0
			f << val
			f.flock ::File::LOCK_UN
			f.chmod 0664
		} && id
	end

	def remove_file(id)
		glob_pattern = "#{file_prefix}#{pattern_for id.to_a}*"
		files = ::Dir.chdir(@dir) { ::Dir.glob glob_pattern } # may include child files
		files.each {|file|
			::File.unlink ::File.join(@dir,file)
		}
	end

end
