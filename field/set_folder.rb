# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Field::Set::Folder < Sofa::Field::Set

	def initialize(meta = {})
		meta[:html] = load_html meta
		super
	end

	private

	def item
# seek the real directory, then @item_object
	end

	def load_html(meta)
		meta[:dir] = meta[:parent] ? File.join(meta[:parent][:dir],meta[:id]) : meta[:id]
		File.open(File.join Sofa::ROOT_DIR,meta[:dir],'_.html') {|f|
			f.read
		}
	end

end

