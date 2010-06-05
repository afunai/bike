# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Runo::Set::Static::Folder < Runo::Set::Static

	def self.root
		self.new(:id => '')
	end

	def initialize(meta = {})
		meta[:dir]  = meta[:parent] ? ::File.join(meta[:parent][:dir],meta[:id]) : meta[:id]
		meta[:html] = load_html(meta[:dir],meta[:parent])
		super

		::Dir.glob(::File.join Runo['skin_dir'],my[:html_dir].to_s,'*.html').each {|f|
			action = ::File.basename(f,'.*').intern
			if action != :index
				html_action = load_html(my[:html_dir].to_s,my[:parent],action)
				merge_meta(@meta,Runo::Parser.parse_html(html_action,action),action)
			end
		}

		@meta.keys.each {|k|
			@meta[k].sub!(/<head>([\s\n]*)/i) {
				"#{$&}<base href=\"@(base_href)\" />#{$1}"
			} if k.to_s =~ /^tmpl(?:_.+)?$/
		}

		my[:item]['_label'] = {:klass => 'text'}
		my[:item]['_owner'] = {:klass => 'meta-owner'}
		my[:item]['_group'] = {:klass => 'meta-group'}
		load load_val(my[:dir],my[:parent])
	end

	def meta_html_dir
		if ::File.readable? ::File.join(Runo['skin_dir'],my[:dir],'index.html')
			my[:dir]
		elsif my[:parent]
			my[:parent][:html_dir]
		end
	end

	def meta_base_href
		Runo.base ? "#{Runo.base[:uri]}#{my[:dir]}/" : "#{my[:dir]}/"
	end

	private

	def _get(arg)
		if arg['main'] && action_tmpl = my[:"tmpl_#{arg['main'][:action]}"]
			_get_by_tmpl(arg,action_tmpl)
		else
			super
		end
	end

	def collect_item(conds = {},&block)
		if conds[:id] =~ Runo::REX::ID && sd = item('main')
			return sd.instance_eval { collect_item(conds,&block) }
		elsif (
			conds[:id] =~ /\A\w+\z/ &&
			::File.directory?(::File.join Runo['skin_dir'],my[:dir],conds[:id])
		)
			my[:item][conds[:id]] = {:klass  => 'set-static-folder'}
		end
		super
	end

	def load_html(dir,parent,action = 'index')
		html_file = ::File.join Runo['skin_dir'],dir,"#{action}.html"
		if ::File.exists? html_file
			::File.open(html_file) {|f| f.read }
		elsif parent
			parent[:html]
		end
	end

	def load_val(dir,parent)
		val_file = ::File.join(Runo['skin_dir'],dir,'index.yaml')
		v = ::File.exists?(val_file) ? ::File.open(val_file) {|f| YAML.load f.read } : {}
		parent ? {
			'_label' => parent.val('_label'),
			'_owner' => parent.val('_owner'),
		}.merge(v) : v
	end

	def merge_meta(meta,action_meta,action)
		meta[:"tmpl_#{action}"] = action_meta[:tmpl]
		meta[:item].each {|id,val|
			merge_meta(val,action_meta[:item][id],action) if action_meta[:item][id]
		} if action_meta[:item]
		meta
	end

end

