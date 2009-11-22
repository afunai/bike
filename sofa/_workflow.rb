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

	def permit_get?(arg)
		_permit?(@sd[:role],arg[:action]) ||
		(arg[:action] != :create && _permit?(@sd.role_on_items(arg[:conds]),arg[:action]))
	end

	def permit_post?(val)
		val.all? {|id,v|
			case id
				when Sofa::Set::Dynamic::REX_NEW_ID
					action = :create
				when Sofa::Storage::REX_ID
					action = v['_action'] ? v['_action'].intern : :update
				when /^_submit/
					next true # not a item value
			end
			_permit?(@sd[:role],action) ||
			(action != :create && _permit?(@sd.role_on_items(:id => id),action))
		}
	end

	def _permit?(role,action)
		perm = self.class.const_get(:PERM)[action]
		perm && perm =~ case role
			when :admin
				/^o.../
			when :group
				/^.o../
			when :owner
				/^..o./
			when :guest
				/^...o/
			else
				/.\A/ # never matches
		end ? true : false
	end

	def before_get(arg)
	end

	def filter(html)
		html
	end

	def before_post(action,v)
	end

	def after_post
	end

end


class Sofa::Workflow::Blog < Sofa::Workflow

	PERM = {
		:create => 'oo--',
		:read   => 'oooo',
		:update => 'o-o-',
		:delete => 'oo--',
	}

end
