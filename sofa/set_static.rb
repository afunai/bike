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
		items = pending_items
		items.each {|id,item| item.commit type }
		if pending_items.empty?
			@result = (@action == :update) ? items : @action
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

def _g_action_update(arg)
	'[u]'
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
		html = gsub_block(html,'sofa-\w+') {|open,inner,close|
			id = open[/id="(.+?)"/i,1] || 'main'
			item[id] = parse_block(open,inner,close)
			"$(#{id})"
		}
# TODO: parse_action_tmpl eg. <div id="main-submit">...</div> -> item['main']['tmpl_submit']
		html = gsub_scalar(html) {|id,meta|
			item[id] = meta
			"$(#{id})"
		}
		{
			:item => item,
			:tmpl => html,
		}
	end

	def gsub_block(html,class_name,&block)
		rex_open_tag = /\s*<(\w+).+?class=(?:"|"[^"]*?\s)#{class_name}(?:"|\s).*?>\n?/i 
		out = ''
		s = StringScanner.new html
		until s.eos?
			if s.scan rex_open_tag
				open_tag = s[0]
				inner_html,close_tag = scan_inner_html(s,s[1])
				close_tag << "\n" if s.scan /\n/
				out << block.call(open_tag,inner_html,close_tag)
			else
				out << s.scan(/.+?(?=\t| |<|\z)/m)
			end
		end
		out
	end

	def gsub_scalar(html,&block)
		out = ''
		s = StringScanner.new html
		until s.eos?
			if s.scan /(\w+):\(([\w\-]+)\s*/m
				out << block.call(s[1],{:klass => s[2]}.merge(scan_tokens s))
			else
				out << s.scan(/.+?(?=\w|<|\z)/m)
			end
		end
		out
	end

	def parse_block(open_tag,inner_html,close_tag)
		open_tag.sub!(/id=".*?"/i,'id="@(name)"')
		workflow = open_tag[/class=(?:"|".*?\s)sofa-(\w+)/,1]

		if inner_html =~ /<(\w+).+?class=(?:"|"[^"]*?\s)body(?:"|\s)/i
			item_html = nil
			sd_tmpl = gsub_block(inner_html,'body') {|open,inner,close|
				item_html = open + inner + close
				'$()'
			}
		else
			item_html = inner_html
			sd_tmpl = '$()'
		end

		sd = {
			:klass     => 'set-dynamic',
			:workflow  => workflow,
			:tmpl      => "#{open_tag}#{sd_tmpl}#{close_tag}",
			:item_html => item_html,
		}
		(inner_html =~ /\A\s*<!--(.+?)-->/m) ? sd.merge(scan_tokens StringScanner.new($1)) : sd
	end

	def parse_token(prefix,token,meta = {})
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
					when /^(-?\d+)?\.\.(-?\d+)?$/
						meta[:min] = $1.to_i if $1
						meta[:max] = $2.to_i if $2
					when /^(\d+)\*(\d+)$/
						meta[:width]  = $1.to_i
						meta[:height] = $2.to_i
					else
						meta[:tokens] ||= []
						meta[:tokens] << token
				end
		end
		meta
	end

	def scan_inner_html(s,name)
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

	def scan_tokens(s)
		meta = {}
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

	def val_cast(v)
		v.is_a?(::Hash) ? v : {:self => v}
	end

end
