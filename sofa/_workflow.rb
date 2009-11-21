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

	def permit?(params,method = :get)
		return true if _permit?(@sd[:role],params[:action])
		if method == :get
			conds = params[:conds]
		else
			conds = {:id => params.keys.select {|k| k =~ Sofa::Storage::REX_ID }}
		end
		params[:action] != :create && _permit?(@sd.role_on_items(conds),params[:action])
	end

	private

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

end


class Sofa::Workflow::Blog < Sofa::Workflow

	PERM = {
		:create => 'oo--',
		:read   => 'oooo',
		:update => 'o-o-',
		:delete => 'oo--',
	}

end
