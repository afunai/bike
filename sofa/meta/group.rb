# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Runo::Meta::Group < Runo::Field

	include Runo::Meta

	private

	def _post(action,v)
		if action == :load
			@val = val_cast v
		end
		nil
	end

end
