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

	def get(arg = {})
		arg[:action] = default_action unless permit_get? arg
		if arg[:action]
			@workflow.before_get arg
			@workflow.filter_get super
		else
			"forbidden: #{my[:name]}"
		end
	end

	def post(action,v = nil)
		return super unless action == :update # the 'root' set can only be updated

		if permit_post? v
			@workflow.before_post(action,v)
			super
			@workflow.after_post
			self
		else
			raise Sofa::Error::Forbidden.new "forbidden: #{action} '#{my[:full_name]}'"
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

	def permit_get?(arg)
		permit?(arg[:action]) || collect_item(arg[:conds] || {}).any? {|item|
			item.permit? arg[:action]
		}
	end

	def permit_post?(val)
		val.all? {|id,v|
			case id
				when Sofa::Set::Dynamic::REX_NEW_ID
					action = :create
				when Sofa::Storage::REX_ID
					action = v['_action'] ? v['_action'].intern : :update
				when /^_submit/
					next true # not a item value
			end
			permit?(action) || (action != :create && item(id) && item(id).permit?(action))
		}
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
			id[REX_NEW_ID] ? @item_object[id].load_default : @item_object[id].load(@storage.val id)
		end
		@item_object[id]
	end

end
