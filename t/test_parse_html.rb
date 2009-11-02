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
		result = @map.send(:parse_html,'hello foo:(bar "baz baz") world')
		assert_equal(
			{'foo' => ['bar','baz baz']},
			result[:meta],
			'Map#parse_html should be able to parse empty sofa tags'
		)
		assert_equal(
			'hello %%foo%% world',
			result[:tmpl],
			'Map#parse_html[:tmpl] should be a proper template'
		)

		result = @map.send(:parse_html,<<'_html')
<h1>foo:(bar "baz baz")</h1>
<p>bar:(1 2 3)</p>
_html
		assert_equal(
			{'foo' => ['bar','baz baz'],'bar' => ['1','2','3']},
			result[:meta],
			'Map#parse_html should be able to parse empty sofa tags'
		)
		assert_equal(
			<<'_html',
<h1>%%foo%%</h1>
<p>%%bar%%</p>
_html
			result[:tmpl],
			'Map#parse_html[:tmpl] should be a proper template'
		)
	end

	def test_obscure_markup
		result = @map.send(:parse_html,'hello foo:(bar baz:(1) baz) world')
		assert_equal(
			{'foo' => ['bar','baz:(1']},
			result[:meta],
			'Map#parse_html should not parse nested empty tag'
		)
		assert_equal(
			'hello %%foo%% baz) world',
			result[:tmpl],
			'Map#parse_html[:tmpl] should be a proper template'
		)

		result = @map.send(:parse_html,'hello foo:(bar baz world')
		assert_equal(
			{'foo' => ['bar','baz','world']},
			result[:meta],
			'Map#parse_html should be able to parse a tag that is not closed'
		)
		assert_equal(
			'hello %%foo%%',
			result[:tmpl],
			'Map#parse_html should be able to parse a tag that is not closed'
		)
	end

	def test_parse_duplicate_tag
		result = @map.send(:parse_html,'hello foo:(bar "baz baz") world foo:(boo)!')
		assert_equal(
			{'foo' => ['boo']},
			result[:meta],
			'definition tags are overridden by a preceding definition'
		)
		assert_equal(
			'hello %%foo%% world %%foo%%!',
			result[:tmpl],
			'Map#parse_html[:tmpl] should be a proper template'
		)
	end

	def test_parse_block_tag
return
		result = @map.send(:parse_html,<<'_html')
<ul class="sofa-list" sofa-id="foo" sofa-bar="baz">
	<li>hello</li>
</ul>
_html
		assert_equal(
			{'foo' => {'bar' => 'baz'}},
			result[:meta],
			'Map#parse_html should be able to parse block sofa tags'
		)
return
		assert_equal(
			<<'_html',
_html
			result[:tmpl],
			'Map#parse_html[:tmpl] should be a proper template'
		)
	end

end
