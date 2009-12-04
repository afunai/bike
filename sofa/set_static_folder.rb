# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Set::Static::Folder < Sofa::Set::Static

	DEFAULT_ITEMS = {
		'_owner' => {:klass => 'meta-owner'},
		'_group' => {:klass => 'meta-group'},
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
		if conds[:id] =~ Sofa::REX::ID && sd = item('main')
			return sd.instance_eval { collect_item(conds,&block) }
		elsif (
			conds[:id] =~ /\A\w+\z/ &&
			::File.directory?(::File.join Sofa['ROOT_DIR'],my[:dir],conds[:id])
		)
			my[:item][conds[:id]] = {:klass  => 'set-static-folder'}
		end
		super
	end

	def load_html(dir,parent)
		html_file = ::File.join Sofa['ROOT_DIR'],dir,'_.html'
		if ::File.exists? html_file
			::File.open(html_file) {|f| f.read }
		elsif parent
			parent[:html]
		end
	end

	def load_val(dir,parent)
		val_file = ::File.join Sofa['ROOT_DIR'],"#{dir}.yaml"
		val_file = Sofa['ROOT_DIR'].sub(/\/?$/,'.yaml') if dir == ''
		v = ::File.exists?(val_file) ? ::File.open(val_file) {|f| YAML.load f.read } : {}
		parent ? {
			'_label' => parent.val('_label'),
			'_owner' => parent.val('_owner'),
		}.merge(v) : v
	end

	def parse_block(open,inner,close)
		sd = super
		sd[:tmpl] += <<_html if sd[:tmpl] !~ /\$\(\.submit\)/
<div>$(.submit)</div>
_html
		sd[:tmpl] = <<_html
<form id="@(name)" method="post" action="@(dir)/update.html">
#{sd[:tmpl]}</form>
_html
		sd
	end

end

