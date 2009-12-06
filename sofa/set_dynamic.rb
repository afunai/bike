# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Set::Dynamic < Sofa::Field

	include Sofa::Set

	attr_reader :storage,:workflow

	def initialize(meta = {})
		meta[:tmpl] = "#{meta[:tmpl]}$(.submit)" unless meta[:tmpl] =~ /\$\(\.submit\)/
		meta[:tmpl] = <<_html if meta[:parent].is_a? Sofa::Set::Static::Folder
<form id="@(name)" method="post" action="@(dir)/update.html">
#{meta[:tmpl]}</form>
_html
		@meta        = meta
		@storage     = Sofa::Storage.instance self
		@workflow    = Sofa::Workflow.instance self
		@item_object = {}
	end

	def meta_dir
		my[:folder][:dir] if my[:folder]
	end

	def commit(type = :temp)
		items = pending_items
		if @storage.is_a? Sofa::Storage::Temp
			items.each {|id,item|
				action = item.action
				item.commit(type) && _commit(action,id,item)
			}
		elsif type == :persistent
			items.each {|id,item|
				action = item.action
				item.commit(:temp) && _commit(action,id,item) && item.commit(:persistent)
			}
		end
		if pending_items.empty?
			@result = (@action == :update) ? items : @action
			@action = nil
			self
		end
	end

	private

	def _val
		@storage.val
	end

	def _get(arg)
		@workflow.before_get arg

		if _hide? arg
			out = ''
		elsif arg[:action] == :create
			item_instance('_1')
			out = _get_by_tmpl({:action => :create,:conds => {:id => '_1'}},my[:tmpl])
		else
			out = super
		end

		@workflow.filter_get arg,out
	end

	def _get_by_self_reference(arg)
		if _hide? arg
			''
		elsif action_tmpl = my["tmpl_#{arg[:action]}".intern]
			# action_tmpl should be resolved here to prevent an infinite reference.
			action_tmpl.gsub(/\$\((?:\.([\w\-]+))?\)/) {
				self_arg = $1 ? arg.merge(:action => $1.intern) : arg
				_get_by_method self_arg
			}
		else
			_get_by_method arg
		end
	end

	def _hide?(arg)
		(arg[:p_action] && arg[:p_action] != :read && !@workflow.is_a?(Sofa::Workflow::Attachment)) ||
		(arg[:orig_action] == :read && arg[:action] == :submit)
	end

	def _g_submit(arg)
		@workflow._g_submit arg
	end

	def _post(action,v = nil)
		@workflow.before_post(action,v)
		case action
			when :update
				v.each_key {|id|
					next unless id.is_a? ::String
					item = item_instance id
					item_action = id[Sofa::REX::ID_NEW] ? :create : (v[id][:delete] ? :delete : :update)
					item.post(item_action,v[id])
				}
			when :load,:load_default,:create
				@storage.build v
		end
		@workflow.after_post
	end

	def _commit(action,id,item)
		case action
			when :create
				new_id = @storage.store(:new_id,item.val)
				item[:id] = new_id
			when :update
				@storage.store(item[:id],item.val)
				@storage.delete(id) if item[:id] != id
			when :delete
				@storage.delete(id)
		end
	end

	def collect_item(conds = {},&block)
		@storage.select(conds).collect {|id|
			item = item_instance id
			block ? block.call(item) : item
		}
	end

	def item_instance(id)
		unless @item_object[id]
# TODO: cache the parsed item_html
			@item_object[id] = Sofa::Field.instance(
				:id     => id,
				:parent => self,
				:klass  => 'set-static',
				:html   => my[:item_html]
			)
			if id[Sofa::REX::ID_NEW]
				@item_object[id].load_default
			else
				@item_object[id].load(@storage.val id)
			end
		end
		@item_object[id]
	end

end
