# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

module Sofa::Meta

	def post(action,v = nil)
		raise Sofa::Error::Forbidden unless permit_post?(action,v)

		_post(action,val_cast(v))
		my[:parent][klass_id] = val if my[:parent]

		@result = nil
		@action = nil
		self
	end

	private

	def klass_id
		self.class.to_s[/\w+$/].downcase.intern
	end

end
