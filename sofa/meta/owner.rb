# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Meta::Owner < Sofa::Field

	include Sofa::Meta

	private

	def _post(action,v)
		if action == :load
			@val = val_cast v
		elsif action == :create
			@val = Sofa.client
		end
		nil
	end

end
