# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Field::Text < Sofa::Field

	def initialize(meta = {})
		meta[:size] = $&.to_i if meta[:tokens].first =~ /^\d+$/
		super
	end

end

