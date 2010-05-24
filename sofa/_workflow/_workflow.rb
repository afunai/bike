# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Workflow

	include Sofa::I18n

	DEFAULT_META = {
		:item_label => Sofa::I18n.n_('item','items',1),
	}
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

	def next_action(base)
		(!base.result || base.result.values.all? {|item| item.permit? :read }) ? :read_detail : :done
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
<input name="#{@sd[:short_name]}.status-public" type="submit" value="#{_ action.to_s}" />
_html
	end

	def _g_submit_confirm(arg)
		label = _ 'confirm'
		<<_html if @sd[:confirm] && arg[:orig_action] != :confirm
<input name="#{@sd[:short_name]}.action-confirm_#{arg[:orig_action]}" type="submit" value="#{label}" />
_html
	end

	def _g_submit_confirm_delete(arg)
		if (
			@sd.send(:permit_get?,arg.merge(:action => :delete)) &&
			!@sd.send(:collect_item,arg[:conds]).all? {|item| item[:id][Sofa::REX::ID_NEW] } &&
			arg[:orig_action] != :confirm
		)
			<<_html
<input name="#{@sd[:short_name]}.action-confirm_delete" type="submit" value="#{_ 'delete...'}" />
_html
		end
	end

end
