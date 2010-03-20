# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'rubygems'
require 'rack/utils'

$KCODE = 'UTF8'

class Sofa::Field

	DEFAULT_META = {}

	def self.instance(meta = {})
		k = meta[:klass].to_s.split(/-/).inject(Sofa) {|c,name|
			name = name.capitalize
			c.const_get(name)
		}
		k.new(meta) if k < self
	end

	attr_reader :action,:result

	def initialize(meta = {})
		@meta = self.class.const_get(:DEFAULT_META).merge meta
		@val  = val_cast(nil)
	end

	def inspect
		caller.grep(/`inspect'/).empty? ? super : "<#{self.class} name=\"#{my[:name]}\">"
	end

	def [](id,*arg)
		respond_to?("meta_#{id}") ? __send__("meta_#{id}",*arg) : @meta[id]
	end

	def []=(id,v)
		@meta[id] = v
	end

	def val
		@val
	end

	def item(*item_steps)
		item_steps = item_steps.first if item_steps.first.is_a? ::Array
		item_steps.empty? ? self : nil # scalar has no item
	end

	def meta_name
		my[:parent] && !my[:parent].is_a?(Sofa::Set::Static::Folder) ?
			"#{my[:parent][:name]}-#{my[:id]}" : my[:id]
	end

	def meta_full_name
		my[:parent] ? "#{my[:parent][:full_name]}-#{my[:id]}" : my[:id]
	end

	def meta_short_name
		return '' if Sofa.base && my[:full_name] == Sofa.base[:full_name]
		my[:parent] && Sofa.base && my[:parent][:full_name] != Sofa.base[:full_name] ?
			"#{my[:parent][:short_name]}-#{my[:id]}" : my[:id]
	end

	def meta_folder
		f = self
		f = f[:parent] until f.nil? || f.is_a?(Sofa::Set::Static::Folder)
		f
	end

	def meta_sd
		f = self
		f = f[:parent] until f.nil? || f.is_a?(Sofa::Set::Dynamic)
		f
	end

	def meta_client
		Sofa.client
	end

	def meta_owner
		@meta[:owner] || (my[:parent] ? my[:parent][:owner] : 'root')
	end

	def meta_owners
		my[:parent] ? (my[:parent][:owners] | @meta[:owner].to_a) : @meta[:owner].to_a
	end

	def meta_admins
		(my[:parent] && my[:parent][:folder]) ? my[:parent][:folder][:owners] : ['root']
	end

	def meta_group
		@meta[:group] || (my[:parent] ? my[:parent][:group] : [])
	end

	def meta_roles
		roles  = Sofa::Workflow::ROLE_NONE
		roles |= Sofa::Workflow::ROLE_ADMIN if my[:admins].include? my[:client]
		roles |= Sofa::Workflow::ROLE_GROUP if my[:group].include? my[:client]
		roles |= Sofa::Workflow::ROLE_OWNER if my[:owner] == my[:client]
		roles |= Sofa::Workflow::ROLE_GUEST if roles == Sofa::Workflow::ROLE_NONE
		roles
	end

	def permit?(action)
		return true unless my[:sd]
		return true if my[:sd].workflow.permit?(my[:roles],action)

		i = self
		until i.nil?
			return true if i[:id] =~ Sofa::REX::ID_NEW # descendant of a new item
			i = i[:parent]
		end
	end

	def default_action
		return :read unless my[:sd]
		actions = my[:sd].workflow.class.const_get(:PERM).keys - [:read,:create,:update]
		([:read,:create,:update] + actions).find {|action| permit? action }
	end

	def get(arg = {})
		if permit_get? arg
			_get(arg)
		else
			if arg[:action] && my[:client] == 'nobody'
				arg[:dest_action] = arg[:action]
				arg[:action] = :login
			else
				arg[:action] = default_action
			end
			arg[:action] ? _get(arg) : 'xxx'
		end
	end

	def load_default
		post :load_default
	end

	def load(v = nil)
		post :load,v
	end

	def create(v = nil)
		post :create,v
	end

	def update(v = nil)
		post :update,v
	end

	def delete
		post :delete
	end

	def post(action,v = nil)
		raise Sofa::Error::Forbidden unless permit_post?(action,v)

		_post action,val_cast(v)
		@action = action unless action == :load || action == :load_default
		self
	end

	def commit(type = :temp)
		if valid?
			@result = @action
			@action = nil
			self
		end
	end

	def pending?
		@action ? true : false
	end

	def valid?
		errors.empty?
	end

	def empty?
		val.to_s == ''
	end

	def errors
		[]
	end

	private

	def my
		self
	end

	def _get(arg)
		_get_by_method arg
	end

	def _get_by_method(arg)
		m = "_g_#{arg[:action]}"
		respond_to?(m,true) ? __send__(m,arg) : _g_default(arg)
	end

	def _g_default(arg)
		Rack::Utils.escape_html val.to_s
	end

	def _post(action,v)
		case action
			when :load_default
				@val = val_cast(my[:defaults] || my[:default])
			when :load,:create,:update
				@val = v
		end
	end

	def permit_get?(arg)
		permit? arg[:action]
	end

	def permit_post?(action,v)
		action == :load || action == :load_default || permit?(action)
	end

	def val_cast(v)
		v
	end

end
