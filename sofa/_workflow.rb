# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Workflow

	DEFAULT_META = {}
	DEFAULT_SUB_ITEMS = {}

	ROLE_ADMIN = 0b1000
	ROLE_GROUP = 0b0100
	ROLE_OWNER = 0b0010
	ROLE_GUEST = 0b0001
	ROLE_NONE  = 0b0000

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

	def default_sub_items
		self.class.const_get :DEFAULT_SUB_ITEMS
	end

	def permit?(roles,action)
		case action
			when :login,:done,:message
				true
			when :confirm
				# TODO: permit?(roles,action,sub_action = nil)
				(roles & self.class.const_get(:PERM)[:read].to_i) > 0
			else
				(roles & self.class.const_get(:PERM)[action].to_i) > 0
		end
	end

	def before_post(action,v)
	end

	def after_post
	end

	def next_action(params)
		(@sd.default_action == :read) ? :read_detail : :done
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
		"#{_g_submit_commit arg}#{_g_submit_confirm arg}#{_g_submit_confirm_delete arg}"
	end

	def _g_submit_commit(arg)
		if @sd.send(:collect_item,arg[:conds]).all? {|i| i[:id] =~ Sofa::REX::ID_NEW }
			action = :create
		elsif arg[:orig_action] == :confirm
			action = arg[:sub_action]
		else
			action = arg[:orig_action]
		end
		<<_html unless @sd[:confirm] == :mandatory && arg[:orig_action] != :confirm
<input name="#{@sd[:short_name]}.status-public" type="submit" value="#{action}" />
_html
	end

	def _g_submit_confirm(arg)
		<<_html if @sd[:confirm] && arg[:orig_action] != :confirm
<input name="#{@sd[:short_name]}.action-confirm_#{arg[:orig_action]}" type="submit" value="confirm" />
_html
	end

	def _g_submit_confirm_delete(arg)
		if (
			@sd.send(:permit_get?,arg.merge(:action => :delete)) &&
			!@sd.send(:collect_item,arg[:conds]).all? {|item| item[:id][Sofa::REX::ID_NEW] } &&
			arg[:orig_action] != :confirm
		)
			<<_html
<input name="#{@sd[:short_name]}.action-confirm_delete" type="submit" value="delete..." />
_html
		end
	end

end


class Sofa::Workflow::Blog < Sofa::Workflow

	DEFAULT_META = {
		:p_size => 10,
		:conds  => {:d => '999999',:p => 'last'},
	}

	DEFAULT_SUB_ITEMS = {
		'_owner'   => {:klass => 'meta-owner'},
		'_group'   => {:klass => 'meta-group'},
	}

	PERM = {
		:create => 0b1100,
		:read   => 0b1111,
		:update => 0b1010,
		:delete => 0b1010,
	}

end


class Sofa::Workflow::Enquete < Sofa::Workflow

	DEFAULT_META = {
		:p_size => 10,
		:conds  => {:p => 'last'},
	}

	DEFAULT_SUB_ITEMS = {}

	PERM = {
		:create => 0b0001,
		:read   => 0b1100,
		:update => 0b0000,
		:delete => 0b1100,
	}

end


class Sofa::Workflow::Attachment < Sofa::Workflow

	DEFAULT_META = {
		:p_size => 0,
	}

	PERM = {
		:create => 0b0000,
		:read   => 0b0000,
		:update => 0b0000,
		:delete => 0b0000,
	}

	def permit?(roles,action)
		(action == :login) ||
		(@sd[:parent] && @sd[:parent].permit?(action))
	end

	def _get(arg)
		@sd.instance_eval {
			if arg[:action] == :create || arg[:action] == :update
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
				_get_by_tmpl({:p_action => arg[:p_action],:action => :update},tmpl)
			end
		}
	end

	def _hide?(arg)
		arg[:action] == :submit
	end

end
