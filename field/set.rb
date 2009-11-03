# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'strscan'

class Sofa::Field::Set

	def pinitialize(meta = {},parent = nil)
		@meta = {
			:parent   => parent,
			:workflow => meta[0],
			:html     => meta[1],
		}

		result = parse_html(@meta[:html].to_s)
		@meta[:item_metas] = result[:meta]
		@meta[:tmpl]       = result[:tmpl]

		load_items(@meta[:item_metas])
	end

def [](name)
	@meta[name]
end

def dir
	if my[:parent]
		my[:dir] ? (my[:parent][:dir] + '/' + my[:dir]) : my[:parent][:dir]
	else
		
	end
end

	private

	def load_html(dir)
	end

	def parse_html(html)
		meta = {}
		tmpl = ''

		s = StringScanner.new html
		until s.eos?
			if s.scan /(\w+):\(/m
				tmpl << "%%#{s[1]}%%"
				meta[s[1]] = parse_tokens(s)
			elsif s.scan /<(\w+)(.+?class="[^"]*?sofa-(\w+).+?)>/
				tag = s[1]
				id  = s[2].match(/id="(.+?)"/)[1]

				tmpl << "%%#{id}%%"
				meta[id] = ['list',s[3],parse_contents(s,tag)]
			else
				tmpl << s.scan(/.+?(?=\w|<|\z)/m)
			end
		end
		{
			:meta => meta,
			:tmpl => tmpl,
		}
	end

	def parse_tokens(s)
		tokens = []
		until s.eos? || s.scan(/\)/)
			if s.scan /(["'])(.*?)(\1|$)/
				tokens << s[2]
			elsif s.scan /[^\s\)]+/
				tokens << s[0]
			else
				s.scan /\s+/
			end
		end
		tokens
	end

	def parse_contents(s,tag)
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

