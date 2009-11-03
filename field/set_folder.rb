# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'strscan'

class Sofa::Field::Set::Folder < Sofa::Field::Set

	def initialize(meta = [],parent = nil)
		id,workflow,dir = *meta

		html = load_html(dir) || ''
		super([id,workflow,html],parent)
	end

	private

	def load_html(dir)
	end

end

