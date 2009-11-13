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

	attr_reader :action

	def initialize(meta = {})
		@meta = meta
		@val  = val_cast(nil)
	end

	def inspect
		caller.grep(/`inspect'/).empty? ? super : "<#{self.class} name=\"#{my[:name]}\">"
	end

	def [](id)
		respond_to?("meta_#{id}") ? __send__("meta_#{id}") : @meta[id]
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

	def folder
		f = self
		f = f[:parent] until f.nil? || f.is_a?(Sofa::Set::Static::Folder)
		f
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

	def pending?
		@action ? true : false
	end

	def deleted?
		@action == :delete
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
		tmpl.gsub(/(@|\$)\((.*?)\)/) {
			if $1 == '@'
				my[$2.intern]
			elsif item = item($2)
				item.get(:action => arg[:action])
			else
				_get(arg)
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


__END__


def []=(id,v)
	@meta[id] = v
end

def meta_name
	my[:parent] && !my[:parent][:name_base] ? "#{my[:parent][:name]}-#{my[:id]}" : my[:id]
end

def meta_full_name
	my[:parent] ? "#{my[:parent][:full_name]}-#{my[:id]}" : my[:id]
end

def owners
	my[:parent] ? (my[:parent].owners() | my[:owner].to_a) : my[:owner].to_a
end


def dir
	if my[:parent]
		my[:dir] ? (my[:parent][:dir] + '/' + my[:dir]) : my[:parent][:dir]
	else
		
	end
end




def valid?
	errors().to_a.empty?
end

def errors
end

def commit(option = {})
	if pending? && valid?
		if persistent? || option[:item_steps]
			@action = nil
		else
			persistent_commit
		end
	end
	self
end

def persistent_commit(f = self)
	item_steps = []
	until f.persistent? || f[:parent].nil?
		item_steps.unshift f[:id]
		f = f[:parent]
	end
	f.commit(:item_steps => item_steps) # item_steps should never be nil
end

def get(arg = {})
	arg[:style_steps] = arg[:style].to_s.split('.') if arg[:style_steps].to_a.empty?

	item_steps = arg[:item_steps] || arg[:name].to_s.split('-') 
	return _get_item(arg,item_steps) unless item_steps.empty?

	return _get_by_tmpl(arg,arg[:tmpl]) if arg[:tmpl]

	style = arg[:style_steps].first
	style = 'read' unless my["tmpl_#{style}"] || respond_to?("get_#{style}",true)
	if (tmpl = my["tmpl_#{style}"]) && !arg[:item_tmpl]
		_get_by_tmpl(arg,tmpl)
	else
		_get(arg)
	end
end


private


def _post(action,v)
	case action
		when 'load_default'
			@val = val_cast(my[:default])
		when 'load','create','update'
			@val = v
	end
end

def _get(arg)
	style = arg[:style_steps].first
# TODO: ↓ style == 'list' の時に下位 list を根こそぎ展開しにいくバカ動作の対策なんだが、これで正しいか？
	arg[:style_steps].shift unless (
		arg[:style_steps].size == 1 &&
		['read','create','update'].include?(style)
	)

	m = "get_#{style}"
	respond_to?(m,true) ? __send__(m,arg) : get_read(arg)
end

def _get_item(arg,item_steps)
	item_id = item_steps.pop
	parent  = item_steps.empty? ? self : item(item_steps)

	if item_id =~ /^@/ # treat the meta like an item
		Rack::Utils.escape_html(parent[item_id.sub('@','')].to_s)
	elsif item = parent.item(item_id)
		item_arg = (item_steps + [item_id]).inject(arg) {|a,s| a[s] || {} }
		item_arg.merge!(
			:style_steps => arg[:style_steps],
			:tmpl        => arg[:tmpl],
			:item_tmpl   => arg[:item_tmpl],
			:join_tmpl   => arg[:join_tmpl],
			:base_arg    => arg[:base_arg] || arg # for blocks
		)
		item.get(item_arg)
	end
end

def get_read(arg = nil)
	Rack::Utils.escape_html(val().to_s)
end


