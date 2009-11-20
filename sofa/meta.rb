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
		self.class.to_s[/\w+$/].downcase
	end

end


class Sofa::Meta::Owner < Sofa::Field

	include Sofa::Meta

	def post(action,v)
		super if action == :load || action == :create
	end

end
