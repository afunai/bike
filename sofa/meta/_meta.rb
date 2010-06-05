# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

module Runo::Meta

	def post(action,v = nil)
		super
		my[:parent][klass_id] = val if my[:parent]
		self
	end

	private

	def klass_id
		self.class.to_s[/\w+$/].downcase.intern
	end

end
