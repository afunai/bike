# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'yaml'

class Sofa::Field::Set::Folder < Sofa::Field::Set

	def initialize(meta = {})
		meta[:dir]  = meta[:parent] ? File.join(meta[:parent][:dir],meta[:id]) : meta[:id]
		meta[:html] = load_html(meta[:dir],meta[:parent])
		super
		my[:item]['label'] = {:klass => 'text'}
		my[:item]['owner'] = {:klass => 'text'}
		load load_val(my[:dir],my[:parent])
	end

	private

	def collect_item(conditions = :all,&block)
		if (
			conditions.is_a?(::String) &&
			conditions =~ /\A\w+\z/ &&
			File.directory?(File.join Sofa::ROOT_DIR,my[:dir],conditions)
		)
			my[:item][conditions] = {:klass  => 'set-folder'}
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
			'label' => parent.val('label'),
			'owner' => parent.val('owner'),
		}.merge(v) : v
	end

end

