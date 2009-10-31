# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'strscan'
class Map
	private
	def parse_token(str)
		tokens = []
		s = StringScanner.new(str)
		until s.eos?
			if s.scan /\S+/mx
				tokens << s[0]
			else
				s.scan(/./)
			end
		end
		tokens
	end
end

class TC_Parse_HTML < Test::Unit::TestCase

	def setup
		@map = Map.new
	end

	def teardown
	end

	def test_parse_token
		assert_equal(
			['foo','bar','baz'],
			@map.instance_eval { parse_token('foo bar baz') },
			'Map#parse_token shoud be able to parse unquoted tokens into array'
		)
	end

end
