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
			if s.scan /(.*?)(\w+):\(/
				tmpl << s[1]
				meta[s[2]] = parse_tokens(s)
			else
				tmpl << s.scan(/.+/)
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

