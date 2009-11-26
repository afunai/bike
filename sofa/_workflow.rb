# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Workflow

	ROLE_ADMIN = 0b1000
	ROLE_GROUP = 0b0100
	ROLE_OWNER = 0b0010
	ROLE_GUEST = 0b0001

	PERM = {
		:create => 0b1111,
		:read   => 0b1111,
		:update => 0b1111,
		:delete => 0b1111,
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

	def permit?(roles,action)
		(roles & self.class.const_get(:PERM)[action].to_i) > 0
	end

	def before_get(arg)
	end

	def filter_get(out)
		out
	end

	def before_post(action,v)
	end

	def after_post
	end

end


class Sofa::Workflow::Blog < Sofa::Workflow

	PERM = {
		:create => 0b1100,
		:read   => 0b1111,
		:update => 0b1110,
		:delete => 0b1010,
	}

end


class Sofa::Workflow::Attachment < Sofa::Workflow

	PERM = {
		:create => 0b1010,
		:read   => 0b1111,
		:update => 0b1010,
		:delete => 0b1010,
	}

end
