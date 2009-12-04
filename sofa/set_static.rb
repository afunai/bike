# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'strscan'

class Sofa::Set::Static < Sofa::Field

	include Sofa::Set

	DEFAULT_ITEMS = {
		'_owner'   => {:klass => 'meta-owner'},
		'_group'   => {:klass => 'meta-group'},
		'_status'  => {:klass => 'text'},
		'_updated' => {:klass => 'text'},
	}

	def initialize(meta = {})
		@meta = meta.merge parse_html(meta[:html].to_s)
		@meta[:item].merge! self.class.const_get(:DEFAULT_ITEMS)
		@item_object = {}
	end

	def commit(type = :temp)
		pending_items.each {|id,item| item.commit type }
		if pending_items.empty?
			@result = @action
			@action = nil
			self
		end
	end

	private

	def _val
		inject({}) {|v,item|
			v[item[:id]] = item.val unless item.empty?
			v
		}
	end

	def _post(action,v = {})
		each {|item|
			id = item[:id]
			item.post(action,v[id]) if action == :load_default || v.has_key?(id)
		}
	end

	def collect_item(conds = {},&block)
		items = my[:item].keys
		items &= conds[:id].to_a if conds[:id] # select item(s) by id
		items.collect {|id|
			item = @item_object[id] ||= Sofa::Field.instance(
				my[:item][id].merge(:id => id,:parent => self)
			)
			block ? block.call(item) : item
		}
	end

	def parse_html(html)
		item = {}
		tmpl = ''

		s = StringScanner.new html
		until s.eos?
			if s.scan /(\w+):\(/m
				id = s[1]
				tmpl << "$(#{id})"
				item[id] = parse_tokens(s)
			elsif s.scan /<(\w+).+?class=(?:"|"[^"]*?\s)sofa-(\w+).+?>\n?/i
				id = s[0][/id="(.+?)"/i,1] || 'main'
				tmpl << "$(#{id})"
				item[id] = parse_block(s)
# TODO: parse_action_tmpl eg. <div id="main-submit">...</div> -> item['main']['tmpl_submit']
			else
				tmpl << s.scan(/.+?(?=\w|<|\z)/m)
			end
		end
		{
			:item => item,
			:tmpl => tmpl,
		}
	end

	def parse_tokens(s,meta = {})
		until s.eos? || s.scan(/\)/)
			prefix = s[1] if s.scan /([:;,])?\s*/
			if s.scan /(["'])(.*?)(\1|$)/
				token = s[2]
			elsif s.scan /[^\s\):;,]+/
				token = s[0]
			end
			prefix ||= ',' if s.scan /(?=,)/ # 1st element of options
			prefix ||= ';' if s.scan /(?=;)/ # 1st element of defaults

			parse_token(prefix,token,meta)
			s.scan /\s+/
		end
		meta
	end

	def parse_token(prefix,token,meta = {})
		unless meta[:klass]
			meta[:klass] = token
			return meta
		end
		case prefix
			when ':'
				meta[:default] = token
			when ';'
				meta[:defaults] ||= []
				meta[:defaults] << token
			when ','
				meta[:options] ||= []
				meta[:options] << token
			else
				case token
					when /(\d+)\.\.(\d+)/
						meta[:min] = $1.to_i
						meta[:max] = $2.to_i
					when /(\d+)\*(\d+)/
						meta[:width]  = $1.to_i
						meta[:height] = $2.to_i
					else
						meta[:tokens] ||= []
						meta[:tokens] << token
				end
		end
		meta
	end

	def parse_block(s)
		open_tag = s[0].sub(/id=".*?"/i,'id="@(name)"')
		name     = s[1]
		workflow = s[2]

		inner_html,close_tag = parse_inner_html(s,name)

		if inner_html =~ /<(\w+).+?class=(?:"|"[^"]*?\s)body(?:"|\s)/i
			self_tmpl = ''
			s2 = StringScanner.new inner_html
			until s2.eos?
				if s2.scan /\s*<(\w+).+?class=(?:"|"[^"]*?\s)body(?:"|\s).*?>\n?/i
					item_html = s2[0] + parse_inner_html(s2,s2[1]).join
					item_html << "\n" if s2.scan /\n/
					self_tmpl << '$()'
				else
					self_tmpl << s2.scan(/.+?(?=\t| |<|\z)/m)
				end
			end
			self_tmpl = "#{open_tag}#{self_tmpl}#{close_tag}"
		else
			item_html = inner_html
			self_tmpl = "#{open_tag}$()#{close_tag}"
		end

		sd = {
			:klass     => 'set-dynamic',
			:workflow  => workflow,
			:tmpl      => self_tmpl,
			:item_html => item_html,
		}
		if inner_html =~ /\A\s*<!--(.+?)-->/m
			s2 = StringScanner.new $1
			parse_tokens(s2,sd)
		end
		sd
	end

	def parse_inner_html(s,name)
		contents = ''
		gen = 1
		until s.eos? || (gen < 1)
			contents << s.scan(/(.*?)(<#{name}|<\/#{name}>|\z)/m)
			gen += 1 if s[2] == "<#{name}"
			gen -= 1 if s[2] == "</#{name}>"
		end
		contents.gsub!(/\A\n+/,'')
		contents.gsub!(/[\t ]*<\/#{name}>\z/,'')
		[contents,$&]
	end

	def val_cast(v)
		v.is_a?(::Hash) ? v : {:self => v}
	end

end
