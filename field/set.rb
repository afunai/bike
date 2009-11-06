# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'strscan'

class Sofa::Field::Set < Sofa::Field

	include Sofa::Field::Collection

	def initialize(meta = {})
		@meta = meta.merge parse_html(meta[:html].to_s)
		@item_object = {}
	end

	def get(arg = {})
		_get_by_tmpl(arg,my[:tmpl])
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
			item.post(action,v[id]) if (
				action == :load_default || action == :create || v.has_key?(id)
			)
		}
	end

	def collect_item(conditions = :all,&block)
		items = my[:item].keys
		unless conditions == :all
			items &= conditions.to_a # select item(s) by id
		end
		items.collect {|id|
			item = @item_object[id] ||= Sofa::Field.instance(my[:item][id].merge :id => id)
			block ? block.call(item) : item
		}
	end

	def parse_html(html)
		item = {}
		tmpl = ''

		s = StringScanner.new html
		until s.eos?
			if s.scan /(\w+):\(/m
				tmpl << "$(#{s[1]})"
				item[s[1]] = parse_tokens(s)
			elsif s.scan /<(\w+).+?class="[^"]*?sofa-(\w+).+?>/
				tag      = s[0]
				name     = s[1]
				workflow = s[2]
				id       = tag.match(/id="(.+?)"/)[1]

				tmpl << "$(#{id})"

				inner_html = parse_inner_html(s,name)
				if inner_html.sub(/<tbody.*?<\/tbody>/im,'$()')
				else
					html = <<_html
#{tag}
</#{tag}>
_html
				end
				item[id] = {
					:klass    => 'list',
					:workflow => workflow,
					:html     => inner_html,
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

	def parse_inner_html(s,name)
		contents = ''
		gen = 1
		until s.eos? || (gen < 1)
			contents << s.scan(/(.*?)(<#{name}|<\/#{name}>|\z)/m)
			gen += 1 if s[2] == "<#{name}"
			gen -= 1 if s[2] == "</#{name}>"
		end
		contents.gsub(/(\A\n+|[\t ]*<\/#{name}>\z)/,'')
	end

	def val_cast(v)
		v.is_a?(::Hash) ? v : {:self => v}
	end

end


__END__



	def _post(action,v = {})
		each {|item|
			id = item[:id]
			item.post(action,v[id]) if (
				action == 'load_default' || action == 'create' || v.has_key?(id)
			)
		}
	end

	def _commit(q,option)
		q.keys.sort.each {|id|
			item = q[id]
			item.commit(option)
		}
		q
	end

	def val_cast(v)
		v.is_a?(::Hash) ? v : {:self => v}
	end

