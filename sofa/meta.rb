# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

module Sofa::Meta

	private

	def _post(action,v)
		super
		my[:parent][klass_id] = val if my[:parent] && !empty?
	end

	def klass_id
		self.class.to_s[/\w+$/].downcase.intern
	end

end


class Sofa::Meta::Owner < Sofa::Field

	include Sofa::Meta

	def post(action,v = nil)
		raise Sofa::Error::Forbidden unless permit_post?(action,v)

		if action == :load
			@val = val_cast(v)
		elsif action == :create
			@val = Sofa.client
			@action = action
		end
		my[:parent][:owner] = val if my[:parent] && !empty?

		self
	end

end


class Sofa::Meta::Group < Sofa::Field

	include Sofa::Meta

# TODO: remove?
def post(action,v)
	super if action == :load || action == :create
end

end
