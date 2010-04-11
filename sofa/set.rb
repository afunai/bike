# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

module Sofa::Set

	include Enumerable

	def val(*steps)
		if steps.empty?
			_val
		elsif i = item(steps)
			i.val
		end
	end

	def item(*item_steps)
		item_steps = item_steps.first if item_steps.first.is_a? ::Array
		return self if item_steps.empty?

		id,*item_steps = item_steps

		if id.is_a?(::String) && child = collect_item(:id => id).first
			item = item_steps.empty? ? child : child.item(*item_steps)
			block_given? ? yield(item) : item
		end
	end

	def pending?
		!pending_items.empty? || action
	end

	def errors
		return {} if action == :delete
		errors = {}
		@item_object.each_pair {|id,item|
			errors[id] = item.errors unless item.valid? || (item.action == :delete)
		}
		errors
	end

	def collect(&block)
		collect_item({},&block)
	end

	def each(&block)
		collect_item.each &block
	end

	private

	def _get(arg)
		if respond_to?("_g_#{arg[:action]}",true)
			_get_by_method arg
		elsif my[:tmpl_summary] && summary?(arg)
			_get_by_tmpl(arg,my[:tmpl_summary])
		else
			_get_by_tmpl(arg,my[:tmpl])
		end
	end

	def _get_by_tmpl(arg,tmpl = '')
		tmpl.gsub(/@\((.+?)\)/) {
			steps = $1.split '-'
			id    = steps.pop
			item  = item steps
			item ? item[id.intern] : '???'
		}.gsub(/\$\((.*?)(?:\.([\w\-]+))?\)/) {
			name,action = $1,$2
			if name == ''
				self_arg = action ?
					arg.merge(:orig_action => arg[:action],:action => action.intern) : arg
				_get_by_self_reference self_arg
			else
				steps = name.split '-'
				item_arg = item_arg(arg,steps)
				item = item steps
				if item.nil?
					'???'
				elsif action
					item_arg = item_arg.merge(
						:orig_action => item_arg[:action],
						:action      => action.intern
					)
					item.instance_eval { _get(item_arg) } # skip the authorization
				else
					item.get(item_arg)
				end
			end
		}.gsub(/^\s+\n/,'')
	end

	def _get_by_self_reference(arg)
		return nil if arg[:action].to_s =~ /^action_/ && arg[:orig_action] != :read
		_get_by_method(arg)
	end

	def _get_by_action_tmpl(arg)
		return nil unless !arg[:recur] && action_tmpl = my["tmpl_#{arg[:action]}".intern]
		_get_by_tmpl(arg.merge(:action => nil,:sub_action => nil,:recur => true),action_tmpl)
	end

	def _g_default(arg,&block)
		collect_item(arg[:conds] || {}) {|item|
			item_arg = item_arg(arg,item[:id])
			next if item.empty? && ![:create,:update].include?(item_arg[:action])
			block ? block.call(item,item_arg) : item.get(item_arg)
		}
	end

	def _g_errors(arg)
		# errors are shown by scalars
	end

	def item_arg(arg,steps)
		steps.to_a.inject(arg) {|a,s|
			i = a[s] || {}
			i[:p_action] = a[:action]
			unless i[:action]
				i[:action]     = a[:action]
				i[:sub_action] = a[:sub_action] if a[:sub_action]
			end
			i
		}
	end

	def summary?(arg)
		[:read,nil].include?(arg[:action]) && !arg[:sub_action]
	end

	def permit_post?(action,val)
		super || val.all? {|id,v|
			if id.is_a? ::Symbol
				true # not a item value
			elsif id =~ Sofa::REX::ID_NEW
				permit? :create
			else
				item_action = v[:action] || :update
				item(id) && item(id).permit?(item_action)
			end
		}
	end

	def pending_items
		@item_object.keys.sort.inject({}) {|h,id|
			h[id] = @item_object[id] if @item_object[id].pending?
			h
		}
	end

end
