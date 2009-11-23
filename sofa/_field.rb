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

	def meta_owner
		@meta[:owner] || (my[:parent] ? my[:parent][:owner] : 'root')
	end

	def meta_owners
		my[:parent] ? (my[:parent][:owners] | @meta[:owner].to_a) : @meta[:owner].to_a
	end

	def meta_admins
		(my[:parent] && my[:parent][:folder]) ? my[:parent][:folder][:owners] : []
	end

	def meta_group
		@meta[:group] || (my[:parent] ? my[:parent][:group] : [])
	end

	def meta_role
		if my[:admins].include? Sofa.client
			:admin
		elsif my[:group].include? Sofa.client
			:group
		elsif my[:owner] == Sofa.client
			:owner
		else
			:guest
		end
	end

	def get(arg = {})
		action = arg[:action]
		action = 'read' unless my[:"tmpl_#{action}"] || respond_to?("_get_#{action}",true)
		if tmpl = my[:"tmpl_#{action}"]
			_get_by_tmpl(arg,tmpl)
		else
			_get(arg)
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
		m = "_get_#{arg[:action]}"
		respond_to?(m,true) ? __send__(m,arg) : _get_read(arg)
	end

	def _get_by_tmpl(arg,tmpl = '')
		tmpl.gsub(/(@|\$)\((.*?)(?:\.(.+?))?\)/) {
			type,name,action = $1,$2,$3
			if type == '@'
				my[name.intern]
			elsif name == ''
				_get arg
			else
				steps = name.split '-'
				item = item steps
				item_arg = arg.dup # TODO: distribute proper sub-arg for the item
				item_arg[:action] = action.intern if action
				item ? item.get(item_arg) : '???'
			end
		}
	end

	def _get_read(arg)
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

	def val_cast(v)
		v
	end

end
