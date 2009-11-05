# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'strscan'

class Sofa::Field::Set < Sofa::Field

	include Sofa::Field::Collection

	def initialize(meta = {})
		@meta = meta.merge parse_html(meta[:html].to_s)
		@item_objects = {}
	end

	private

def _val
	inject({}) {|v,item|
		v[item[:id]] = item.val if item_has_val?(item) && !item.persistent?
		v
	}
end

def collect_item(conditions = :all,&block)
	items = @meta[:items].keys
	unless conditions == :all
		# select item(s) by id
		items &= conditions.to_a
	end
	items.collect {|id|
		@item_object[id] ||= Field.instance(@meta[:items][id])
		block ? block.call(@item_object[id]) : @item_object[id]
	}
end

	def parse_html(html)
		item = {}
		tmpl = ''

		s = StringScanner.new html
		until s.eos?
			if s.scan /(\w+):\(/m
				tmpl << "%%#{s[1]}%%"
				item[s[1]] = parse_tokens(s)
			elsif s.scan /<(\w+)(.+?class="[^"]*?sofa-(\w+).+?)>/
				tag = s[1]
				id  = s[2].match(/id="(.+?)"/)[1]

				tmpl << "%%#{id}%%"
				item[id] = {
					:klass    => 'List',
					:workflow => s[3],
					:html     => parse_inner_html(s,tag),
				}
			else
				tmpl << s.scan(/.+?(?=\w|<|\z)/m)
			end
		end
		{
			:item => item,
			:tmpl => tmpl,
		}
	end

	def parse_tokens(s)
		meta = {}
		until s.eos? || s.scan(/\)/)
			prefix = s[1] if s.scan /([:,])?\s?/
			if s.scan /(["'])(.*?)(\1|$)/
				token = s[2]
			elsif s.scan /[^\s\):,]+/
				token = s[0]
			end
			prefix = ',' if s.scan /(?=,)/ # 1st element of options

			parse_token(prefix,token,meta)
			s.scan /\s+/
		end
		meta
	end

	def parse_token(prefix,token,meta = {})
		case prefix
			when ':'
				if meta[:default]
					meta[:default] = meta[:default].to_a
					meta[:default] << token
				else
					meta[:default] = token
				end
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
						if meta[:klass]
							meta[:tokens] ||= []
							meta[:tokens] << token
						else
							meta[:klass] = token.capitalize
						end
				end
		end
		meta
	end

	def parse_inner_html(s,tag)
		contents = ''
		gen = 1
		until s.eos? || (gen < 1)
			contents << s.scan(/(.*?)(<#{tag}|<\/#{tag}>|\z)/m)
			gen += 1 if s[2] == "<#{tag}"
			gen -= 1 if s[2] == "</#{tag}>"
		end
		contents.gsub(/(\A\n+|[\t ]*<\/#{tag}>\z)/,'')
	end

end

