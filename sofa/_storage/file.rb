# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'rubygems'
require 'yaml'
require 'ya2yaml'
require 'fileutils'

class Sofa::Storage::File < Sofa::Storage

	def self.traverse(dir = '/',root = Sofa['STORAGE']['File']['data_dir'],&block)
		::Dir.glob(::File.join root,dir,'*').sort.collect {|file|
			ftype     = ::File.ftype file
			base_name = ::File.basename file
			id,ext    = base_name.split('.',2)
			id = "main-#{id}" if id =~ Sofa::REX::ID
			full_name = ::File.join(dir,id).gsub(::File::SEPARATOR,'-')

			if ftype == 'file' && id != 'index'
				val = nil
				::File.open(file,'r') {|f|
					f.flock ::File::LOCK_SH
					val = f.read
					f.flock ::File::LOCK_UN
				}
				block.call(
					:dir       => dir,
					:base_name => base_name,
					:full_name => full_name,
					:ext       => ext,
					:val       => (ext == 'yaml' ? YAML.load(val) : val)
				)
			elsif ftype == 'directory' && base_name !~ /\A#{Sofa::REX::DIR_STATIC}\z/
				self.traverse(::File.join(dir,base_name),root,&block)
			end
		}.compact.flatten
	end

	def self.load_skel
		self.traverse('/',Sofa['skin_dir']) {|entry|
			dir = ::File.join(Sofa['STORAGE']['File']['data_dir'],entry[:dir])
			unless ::File.exists? ::File.join(dir,entry[:base_name])
				::FileUtils.mkpath(dir) unless ::File.directory? dir
				::FileUtils.cp(
					::File.join(Sofa['skin_dir'],entry[:dir],entry[:base_name]),
					::File.join(dir,entry[:base_name]),
					{:preserve => true}
				)
			end
		}
	end

	def self.available?
		Sofa['STORAGE']['File'] && Sofa['STORAGE']['File']['data_dir']
	end

	def initialize(sd = nil)
		super
		@dir = Sofa['STORAGE']['File']['data_dir'] + @sd[:folder][:dir] if @sd
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

	def move(old_id,new_id)
		rename_file(old_id,new_id) && new_id
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
		(@sd[:name] == 'main') ? '' : @sd[:name].sub(/^main-/,'') + '-'
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
		if new_id?(id,v)
			old_id = id
			id = new_id v
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
		if old_id && f = ::File.open(::File.join(@dir,file),'a')
			return if f.pos != 0 # duplicate id
			move(old_id,id) unless old_id == :new_id
		end
		::File.open(::File.join(@dir,file),'a') {|f|
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

	def rename_file(old_id,new_id)
		glob_pattern = "#{file_prefix}#{pattern_for old_id.to_a}*"
		files = ::Dir.chdir(@dir) { ::Dir.glob glob_pattern } # may include child files
		rex = /^\A#{file_prefix}#{old_id}/
		files.each {|file|
			to_file = file.sub(rex,"#{file_prefix}#{new_id}")
			::File.rename(::File.join(@dir,file),::File.join(@dir,to_file))
		}
	end

end
