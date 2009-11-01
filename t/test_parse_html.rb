# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

Dir['./field/*.rb'].sort.each {|file| require file }

class TC_Parse_HTML < Test::Unit::TestCase

	def setup
		@map = Map.new
	end

	def teardown
	end

	def test_parse_tokens
		assert_equal(
			['foo','bar','baz'],
			@map.send(:parse_tokens,StringScanner.new('foo bar baz')),
			'Map#parse_tokens should be able to parse unquoted tokens into array'
		)
		assert_equal(
			['foo','bar','baz baz'],
			@map.send(:parse_tokens,StringScanner.new('foo "bar" "baz baz"')),
			'Map#parse_tokens should be able to parse quoted tokens'
		)
		assert_equal(
			['foo','bar','baz'],
			@map.send(:parse_tokens,StringScanner.new("foo 'bar' baz")),
			'Map#parse_tokens should be able to parse quoted tokens'
		)

		assert_equal(
			['foo','bar','baz'],
			@map.send(:parse_tokens,StringScanner.new("foo 'bar' baz) qux")),
			'Map#parse_tokens should stop scanning at an ending bracket'
		)
		assert_equal(
			['foo','bar (bar?)','baz'],
			@map.send(:parse_tokens,StringScanner.new("foo 'bar (bar?)' baz) qux")),
			'Map#parse_tokens should ignore brackets inside quoted tokens'
		)
	end

	def test_parse_empty_tag
		assert_equal(
			{'foo' => ['bar','baz baz']},
			@map.send(:parse_html,'hello foo:(bar "baz baz") world')[:meta],
			'Map#parse_html should be able to parse empty sofa tags'
		)
	end

end
