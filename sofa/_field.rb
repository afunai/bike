# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'rubygems'
require 'rack/utils'

$KCODE = 'UTF8'

class Sofa::Field

	def self.instance(meta = {})
		k = meta[:klass].to_s.split(/-/).inject(Sofa) {|c,name|
			name = name.capitalize
			c.const_get(name)
		}
		k.new(meta) if k < self
	end

	attr_reader :action,:result

	def initialize(meta = {})
		@meta = meta
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
		item_steps.empty? ? self : nil # scalar has no item
	end

	def meta_name
		my[:parent] && !my[:parent].is_a?(Sofa::Set::Static::Folder) ?
			"#{my[:parent][:name]}-#{my[:id]}" : my[:id]
	end

	def meta_full_name
		my[:parent] ? "#{my[:parent][:full_name]}-#{my[:id]}" : my[:id]
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
		roles  = Sofa::Workflow::ROLE_GUEST
		roles |= Sofa::Workflow::ROLE_ADMIN if my[:admins].include? Sofa.client
		roles |= Sofa::Workflow::ROLE_GROUP if my[:group].include? Sofa.client
		roles |= Sofa::Workflow::ROLE_OWNER if my[:owner] == Sofa.client
		roles
	end

	def permit?(action)
		my[:sd] ? my[:sd].workflow.permit?(my[:roles],action) : true
	end

	def default_action
		return :read unless my[:sd]
		actions = my[:sd].workflow.class.const_get(:PERM).keys - [:read,:create,:update]
		([:read,:create,:update] + actions).find {|action| permit? action }
	end

	def get(arg = {})
		permit_get?(arg) ? _get(arg) : 'xxx'
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

	def persistent_commit
		f = self
		f = f[:parent] until f.nil? || (f.storage && !f.storage.is_a?(Sofa::Storage::Temp))
		f ? f.commit(:persistent) : self.commit(:persistent)
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
		action = arg[:action]
		action = :default unless my[:"tmpl_#{action}"] || respond_to?("_get_#{action}",true)
		if tmpl = my[:"tmpl_#{action}"]
			_get_by_tmpl(arg,tmpl)
		else
			_get_by_method(arg)
		end
	end

	def _get_by_method(arg)
		m = "_get_#{arg[:action]}"
		respond_to?(m,true) ? __send__(m,arg) : _get_default(arg)
	end

	def _get_by_tmpl(arg,tmpl = '')
		tmpl.gsub(/(@|\$)\((.*?)(?:\.(.+?))?\)/) {
			type,name,action = $1,$2,$3
			if type == '@'
				my[name.intern]
			elsif name == ''
				_get_by_method arg
			else
				steps = name.split '-'
				item_arg = steps.inject(arg) {|a,s| a[s] || {} }
				item_arg[:action] = action ? action.intern : arg[:action]
				item = item steps
				item ? item.get(item_arg) : '???'
			end
		}
	end

	def _get_default(arg)
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
