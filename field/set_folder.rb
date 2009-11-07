# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Field::Set::Folder < Sofa::Field::Set

	def initialize(meta = {})
		meta[:html] = load_html meta
		super
		my[:item]['label'] = {:klass => 'text'}
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

	def load_html(meta)
		meta[:dir] = meta[:parent] ? File.join(meta[:parent][:dir],meta[:id]) : meta[:id]
		html_file = File.join Sofa::ROOT_DIR,meta[:dir],'_.html'
		if File.exists? html_file
			File.open(html_file) {|f| f.read }
		elsif meta[:parent]
			meta[:parent][:html]
		end
	end

end

