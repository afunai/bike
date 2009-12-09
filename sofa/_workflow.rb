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

	def before_post(action,v)
	end

	def after_post
	end

	def next_action(params)
		(@sd.default_action == :read) ? :index : :done
	end

	def _get(arg)
		@sd.instance_eval {
			if arg[:action] == :create
				item_instance '_001'
				_get_by_tmpl({:action => :create,:conds => {:id => '_001'}},my[:tmpl])
			end
		}
	end

	def _hide?(arg)
		(arg[:p_action] && arg[:p_action] != :read) ||
		(arg[:orig_action] == :read && arg[:action] == :submit)
	end

	def _g_submit(arg)
		<<_html.chomp
<input name="#{@sd[:short_name]}.status-public" type="submit" value="#{arg[:orig_action]}" />
_html
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

	def _get(arg)
		@sd.instance_eval {
			if arg[:action] == :create || arg[:action] == :update
				@item_object.delete '_001'
				new_item = item_instance '_001'

				item_outs = _g_default(arg) {|item,item_arg|
					action = item[:id][Sofa::REX::ID_NEW] ? :create : :delete
					button_tmpl = my["tmpl_submit_#{action}".intern] || <<_html.chomp
<input type="submit" name="@(short_name).action-#{action}" value="#{action}">
_html
					button = item.send(:_get_by_tmpl,{},button_tmpl)
					item_arg[:action] = :create if action == :create
					item_tmpl = item[:tmpl].sub(/.*\$\(.*?\)/,"\\&#{button}")
					item.send(:_get_by_tmpl,item_arg,item_tmpl)
				}
				tmpl = my[:tmpl].gsub('$()',item_outs.join)
				_get_by_tmpl({:action => :update},tmpl)
			end
		}
	end

	def _hide?(arg)
		arg[:action] == :submit
	end

end
