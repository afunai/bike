# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Set::Dynamic < Sofa::Field

	include Sofa::Set

	attr_reader :storage,:workflow

	def initialize(meta = {})
		@meta        = meta
		@storage     = Sofa::Storage.instance self
		@workflow    = Sofa::Workflow.instance self
		@item_object = {}
		unless @workflow.is_a? Sofa::Workflow::Attachment
			my[:tmpl] = "#{my[:tmpl]}$(.submit)" unless my[:tmpl] =~ /\$\(\.submit\)/
			my[:tmpl] = "#{my[:tmpl]}$(.action_create)" unless my[:tmpl] =~ /\$\(\.action_create\)/
			my[:item_html].sub!(
				/:\(.*?\)/m,
				'\&$(.action_update)'
			) if my[:item_html].is_a?(::String) && my[:item_html] !~ /\$\(\.action_update\)/
		end
		my[:tmpl] = <<_html if my[:parent].is_a? Sofa::Set::Static::Folder
<form id="@(name)" method="post" action="/@(tid)@(base_path)/update.html">
#{my[:tmpl]}</form>
_html
	end

	def meta_tid
		unless @meta[:tid]
			t = Time.now
			@meta[:tid] = t.strftime('%m%d%H%M%S.') + t.usec.to_s
		end
		@meta[:tid]
	end

	def meta_dir
		my[:folder][:dir] if my[:folder]
	end

	def meta_path
		"#{my[:dir]}/#{my[:name].gsub('-','/')}"
	end

	def meta_base_path
		Sofa.base ? Sofa.base[:path] : my[:path]
	end

	def commit(type = :temp)
		items = pending_items
		if @storage.is_a? Sofa::Storage::Temp
			items.each {|id,item|
				action = item.action
				item.commit(type) && _commit(action,id,item)
			}
		else
			items.each {|id,item|
				action = item.action || :update
				result = item.commit(:temp)
				if result && type == :persistent
					_commit(action,id,item) && item.commit(:persistent)
				end
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
		if @workflow._hide? arg
			''
		else
			@workflow._get(arg) || super
		end
	end

	def _get_by_self_reference(arg)
		@workflow._hide?(arg) ? '' : super
	end

	def _g_submit(arg)
		@workflow._g_submit arg
	end

	def _g_action_create(arg)
		<<_html
<div><a href="#{_g_uri_create arg}">create</a></div>
_html
	end

	def _g_uri_create(arg)
		"#{my[:path]}/create.html"
	end

	def _post(action,v = nil)
		@workflow.before_post(action,v)
		case action
			when :create,:update
				@storage.build({}) if action == :create

				v.each_key.sort_by {|id| id.to_s }.each {|id|
					next unless id.is_a? ::String
					v[id][:action] ||= id[Sofa::REX::ID_NEW] ? :create : :update
					item_instance(id).post(v[id][:action],v[id])
				}
			when :load,:load_default
				@storage.build v
		end
		@workflow.after_post
	end

	def _commit(action,id,item)
		case action
			when :create
				return if item.empty?
				new_id = @storage.store(:new_id,item.val)
				item[:id] = new_id
			when :update
				@storage.store(item[:id],item.val)
				if item[:id] != id || item.empty?
					@storage.delete(id)
					@item_object.delete id
				end
			when :delete
				@storage.delete(id)
				@item_object.delete id
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
