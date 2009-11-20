# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Set::Static::Folder < Sofa::Set::Static

	DEFAULT_ITEMS = {
		'_owner' => {:klass => 'meta-owner'},
		'_group' => {:klass => 'text'},
		'_label' => {:klass => 'text'},
	}

	def self.root
		self.new(:id => '')
	end

	def initialize(meta = {})
		meta[:dir]  = meta[:parent] ? ::File.join(meta[:parent][:dir],meta[:id]) : meta[:id]
		meta[:html] = load_html(meta[:dir],meta[:parent])
		super
		load load_val(my[:dir],my[:parent])
	end

	private

	def collect_item(conds = {},&block)
		if (
			conds[:id].is_a?(::String) &&
			conds[:id] =~ /\A\w+\z/ &&
			::File.directory?(::File.join Sofa::ROOT_DIR,my[:dir],conds[:id])
		)
			my[:item][conds[:id]] = {:klass  => 'set-static-folder'}
		end
		super
	end

	def load_html(dir,parent)
		html_file = ::File.join Sofa::ROOT_DIR,dir,'_.html'
		if ::File.exists? html_file
			::File.open(html_file) {|f| f.read }
		elsif parent
			parent[:html]
		end
	end

	def load_val(dir,parent)
		val_file = ::File.join Sofa::ROOT_DIR,"#{dir}.yaml"
		val_file = Sofa::ROOT_DIR.sub(/\/?$/,'.yaml') if dir == ''
		v = ::File.exists?(val_file) ? ::File.open(val_file) {|f| YAML.load f.read } : {}
		parent ? {
			'_label' => parent.val('_label'),
			'_owner' => parent.val('_owner'),
		}.merge(v) : v
	end

end

