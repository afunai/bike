# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'strscan'

class Map

	private

	def parse_html(str)
		meta = {}
		tmpl = ''

		s = StringScanner.new str
		until s.eos?
			if s.scan /(\w+):\(/m
				tmpl << "%%#{s[1]}%%"
				meta[s[1]] = parse_tokens(s)
			elsif s.scan /<(\w+)(.+?class="[^"]*?sofa-(\w+).+?)>/
				tag = s[1]
				id  = s[2].match(/id="(.+?)"/)[1]
# scan til the end of the block
				meta[id] = [s[3]]
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

end

