# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Set::Dynamic < Sofa::Field

	include Sofa::Set

	REX_NEW_ID = /^_\d/

	attr_reader :storage,:workflow

	def initialize(meta = {})
		@meta        = meta
		@storage     = Sofa::Storage.instance self
		@workflow    = Sofa::Workflow.instance self
		@item_object = {}
	end

	def role_on_items(conds = {})
		item_ids = @storage.select(conds || {})
		!item_ids.empty? && item_ids.all? {|id|
			item_instance(id)[:owner] == Sofa.client
		} ? :owner : :guest
	end

def get(arg = {})
	arg[:action] ||= :read # TODO: look for a possible action by the client
	if @workflow.permit_get? arg
		@workflow.before_get arg
		@workflow.filter super
	else
		Sofa::Error::Forbidden.new
	end
end

def ppost(action,v = nil)
	if @workflow.permit?(v,:post)
		@workflow.before_post(action,v)
		super
		@workflow.after_post
		self
	else
		Sofa::Error::Forbidden.new
	end
end

	def commit(type = :temp)
		if @storage.is_a? Sofa::Storage::Temp
			pending_items.each {|id,item|
				action = item.action
				item.commit(type) && _commit(action,id,item)
			}
		elsif type == :persistent
			pending_items.each {|id,item|
				action = item.action
				item.commit(:temp) && _commit(action,id,item) && item.commit(:persistent)
			}
		end
		if pending_items.empty?
			@result = @action
			@action = nil
			self
		end
	end

	private

	def _val
		@storage.val
	end

	def _get(arg)
		collect_item(arg[:conds] || {}) {|item|
			item.get arg
		}
	end

	def _post(action,v = nil)
		case action
			when :update
				v.each_key {|id|
					item = item_instance id
					item_action = id[REX_NEW_ID] ? :create : (v[id][:delete] ? :delete : :update)
					item.post(item_action,v[id])
				}
			when :load,:load_default,:create
				@storage.build v
		end
	end

	def _commit(action,id,item)
		case action
			when :create
				@storage.store(:new_id,item.val)
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
		@item_object[id] = Sofa::Field.instance(
			:id     => id,
			:parent => self,
			:klass  => 'set-static',
			:html   => my[:item_html]
		)
		id[REX_NEW_ID] ? @item_object[id].load_default : @item_object[id].load(@storage.val id)
	end
	@item_object[id]
end

end
