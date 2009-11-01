# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'strscan'

class Map

	private

	def parse_tokens(str)
		tokens = []
		s = StringScanner.new(str)
		until s.eos? || s.scan(/\)/)
			if s.scan /(["'])(.*?)(\1|$)/
				tokens << s[2]
			elsif s.scan /[^\s\)]+/
				tokens << s[0]
			else
				s.scan(/\s+/)
			end
		end
		tokens
	end

end

