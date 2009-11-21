# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Workflow

	PERM = {
		:create => 'oooo',
		:read   => 'oooo',
		:update => 'oooo',
		:delete => 'oooo',
	}

	def self.instance(sd)
		klass = sd[:workflow].to_s.capitalize
		if klass != ''
			self.const_get(klass).new sd
		else
			self.new sd
		end
	end

	attr_reader :sd

	def initialize(sd)
		@sd = sd
	end

end


class Sofa::Workflow::Blog < Sofa::Workflow

	PERM = {
		:create => 'oo--',
		:read   => 'oooo',
		:update => 'ooo-',
		:delete => 'o-o-',
	}

end
