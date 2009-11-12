# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'yaml'

class Sofa::Field::Set::Folder < Sofa::Field::Set::Static

	def initialize(meta = {})
		meta[:dir]  = meta[:parent] ? File.join(meta[:parent][:dir],meta[:id]) : meta[:id]
		meta[:html] = load_html(meta[:dir],meta[:parent])
		super
		my[:item]['_label'] = {:klass => 'text'}
		my[:item]['_owner'] = {:klass => 'text'}
		load load_val(my[:dir],my[:parent])
	end

	private

	def collect_item(conds = {},&block)
		if (
			conds[:id].is_a?(::String) &&
			conds[:id] =~ /\A\w+\z/ &&
			File.directory?(File.join Sofa::ROOT_DIR,my[:dir],conds[:id])
		)
			my[:item][conds[:id]] = {:klass  => 'set-folder'}
		end
		super
	end

	def load_html(dir,parent)
		html_file = File.join Sofa::ROOT_DIR,dir,'_.html'
		if File.exists? html_file
			File.open(html_file) {|f| f.read }
		elsif parent
			parent[:html]
		end
	end

	def load_val(dir,parent)
		val_file = File.join Sofa::ROOT_DIR,"#{dir}.yaml"
		v = File.exists?(val_file) ? File.open(val_file) {|f| YAML.load f.read } : {}
		parent ? {
			'_label' => parent.val('_label'),
			'_owner' => parent.val('_owner'),
		}.merge(v) : v
	end

end

