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

		my[:item_arg] = Sofa::Parser.parse_html my[:item_html].to_s
		my[:item_arg][:tmpl].sub!(
			/\$\(.*?\)/m,
			'\&$(.action_update)'
		) unless @workflow.is_a?(Sofa::Workflow::Attachment) ||
			my[:item_arg][:tmpl].include?('$(.action_update)')

my[:p_size] = meta[:max] || 10
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
		(@workflow._get(arg) || super) unless @workflow._hide? arg
	end

	def _get_by_self_reference(arg)
		super unless @workflow._hide?(arg)
	end

	def _g_submit(arg)
		@workflow._g_submit arg
	end

	def _g_action_create(arg)
		_get_by_action_tmpl(arg) || <<_html
<div><a href="#{_g_uri_create arg}">create</a></div>
_html
	end

	def _g_uri_create(arg)
		"#{my[:path]}/create.html"
	end

	def _g_navi(arg)
		arg[:navi] ||= @storage.navi(arg[:conds] || {})
		return unless (arg[:orig_action] == :read) && (arg[:navi][:prev] || arg[:navi][:next])

		div = my[:tmpl_navi] || '<div>$(.navi_prev) | $(.navi_p)$(.navi_next)</div>'
		div.gsub(/\$\(\.(navi_prev|navi_next|navi_p|uri_prev|uri_next)\)/) {
			__send__("_g_#{$1}",arg)
		}
	end

	def _g_navi_prev(arg)
		button = my[:tmpl_navi_prev] || 'prev'
		(uri = _g_uri_prev(arg)) ? "<a href=\"#{my[:path]}/#{uri}\">#{button}</a>" : button
	end

	def _g_navi_next(arg)
		button = my[:tmpl_navi_next] || 'next'
		(uri = _g_uri_next(arg)) ? "<a href=\"#{my[:path]}/#{uri}\">#{button}</a>" : button
	end

	def _g_navi_p(arg)
		uris = _uri_p(arg)
		return unless uris && uris.size > 1

		item_tmpl = nil
		div = my[:tmpl_navi_p] || '<span class="item">$() </span> | '
		div = Sofa::Parser.gsub_block(div,'item') {|open,inner,close|
			item_tmpl = open + inner + close
			'$(.items)'
		}
		div.gsub('$(.items)') {
			uris.collect {|uri|
				p = uri[/p=(\d+)/,1] || '1'
				if arg[:conds][:p] == p
					item_tmpl.gsub('$()',p)
				else
					item_tmpl.gsub('$()',"<a href=\"#{my[:path]}/#{uri}\">#{p}</a>")
				end
			}.join
		}
	end

	def _g_uri_prev(arg)
		arg[:navi] ||= @storage.navi(arg[:conds] || {})
		Sofa::Path.path_of(arg[:navi][:prev]) if arg[:navi][:prev]
	end

	def _g_uri_next(arg)
		arg[:navi] ||= @storage.navi(arg[:conds] || {})
		Sofa::Path.path_of(arg[:navi][:next]) if arg[:navi][:next]
	end

	def _uri_p(arg)
		arg[:navi] ||= @storage.navi(arg[:conds] || {})
		if arg[:navi][:sibs] && arg[:navi][:sibs].keys.first == :p
			base_conds = arg[:conds].dup
			base_conds.delete :p
			conds = arg[:navi][:sibs].values.first
			if arg[:conds] && p = arg[:conds][:p]
				range = ['1',conds.last] + ((p.to_i - 5)..(p.to_i + 5)).to_a.collect {|i| i.to_s }
				conds = conds & range
			end
			conds.collect {|cond|
				Sofa::Path.path_of base_conds.merge(:p => cond)
			}
		end
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
			@item_object[id] = Sofa::Field.instance(
				:id     => id,
				:parent => self,
				:klass  => 'set-static',
				:tmpl   => my[:item_arg][:tmpl],
				:item   => my[:item_arg][:item]
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
