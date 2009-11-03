# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'strscan'

class Sofa::Field::Set::Folder < Sofa::Field::Set

	def initialize(meta = {})
		@meta = meta
		@meta[:html] = load_html(meta[:dir]) || ''

		super
	end

	private

	def load_html(dir)
	end

end

