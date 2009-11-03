# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Set_Parse_HTML < Test::Unit::TestCase

	def setup
		@set = Sofa::Field::Set.new
	end

	def teardown
	end

	def test_parse_tokens
		assert_equal(
			{:klass => 'Foo',:tokens => ['bar','baz']},
			@set.send(:parse_tokens,StringScanner.new('foo bar baz')),
			'Set#parse_tokens should be able to parse unquoted tokens into array'
		)
		assert_equal(
			{:klass => 'Foo',:tokens => ['bar','baz baz']},
			@set.send(:parse_tokens,StringScanner.new('foo "bar" "baz baz"')),
			'Set#parse_tokens should be able to parse quoted tokens'
		)
		assert_equal(
			{:klass => 'Foo',:tokens => ['bar','baz']},
			@set.send(:parse_tokens,StringScanner.new("foo 'bar' baz")),
			'Set#parse_tokens should be able to parse quoted tokens'
		)

		assert_equal(
			{:klass => 'Foo',:tokens => ['bar','baz']},
			@set.send(:parse_tokens,StringScanner.new("foo 'bar' baz) qux")),
			'Set#parse_tokens should stop scanning at an ending bracket'
		)
		assert_equal(
			{:klass => 'Foo',:tokens => ['bar (bar?)','baz']},
			@set.send(:parse_tokens,StringScanner.new("foo 'bar (bar?)' baz) qux")),
			'Set#parse_tokens should ignore brackets inside quoted tokens'
		)
	end

	def test_parse_empty_tag
		result = @set.send(:parse_html,'hello foo:(bar "baz baz") world')
		assert_equal(
			{'foo' => {:klass => 'Bar',:tokens => ['baz baz']}},
			result[:meta],
			'Set#parse_html should be able to parse empty sofa tags'
		)
		assert_equal(
			'hello %%foo%% world',
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)

		result = @set.send(:parse_html,<<'_html')
<h1>foo:(bar "baz baz")</h1>
<p>bar:(a b c)</p>
_html
		assert_equal(
			{
				'foo' => {:klass => 'Bar',:tokens => ['baz baz']},
				'bar' => {:klass => 'A',:tokens => ['b','c']},
			},
			result[:meta],
			'Set#parse_html should be able to parse empty sofa tags'
		)
		assert_equal(
			<<'_html',
<h1>%%foo%%</h1>
<p>%%bar%%</p>
_html
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)
	end

	def test_obscure_markup
		result = @set.send(:parse_html,'hello foo:(bar baz:(1) baz) world')
		assert_equal(
			{'foo' => {:klass => 'Bar',:default => '(1',:tokens => ['baz']}},
			result[:meta],
			'Set#parse_html should not parse nested empty tag'
		)
		assert_equal(
			'hello %%foo%% baz) world',
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)

		result = @set.send(:parse_html,'hello foo:(bar baz world')
		assert_equal(
			{'foo' => {:klass => 'Bar',:tokens => ['baz','world']}},
			result[:meta],
			'Set#parse_html should be able to parse a tag that is not closed'
		)
		assert_equal(
			'hello %%foo%%',
			result[:tmpl],
			'Set#parse_html should be able to parse a tag that is not closed'
		)

		result = @set.send(:parse_html,'hello foo:(bar "baz"world)')
		assert_equal(
			{'foo' => {:klass => 'Bar',:tokens => ['baz','world']}},
			result[:meta],
			'Set#parse_html should be able to parse tokens without a delimiter'
		)
		assert_equal(
			'hello %%foo%%',
			result[:tmpl],
			'Set#parse_html should be able to parse tokens without a delimiter'
		)
	end

	def test_parse_meta
		assert_equal(
			{:width => 160,:height => 120},
			@set.send(:parse_meta,nil,'160*120'),
			'Set#parse_meta should be able to parse dimension tokens'
		)
		assert_equal(
			{:min => 1,:max => 32},
			@set.send(:parse_meta,nil,'1..32'),
			'Set#parse_meta should be able to parse range tokens'
		)

		assert_equal(
			{:options => ['foo']},
			@set.send(:parse_meta,',','foo'),
			'Set#parse_meta should be able to parse option tokens'
		)
		assert_equal(
			{:options => ['foo','bar']},
			@set.send(:parse_meta,',','bar',{:options => ['foo']}),
			'Set#parse_meta should be able to parse option tokens'
		)

		assert_equal(
			{:default => 'foo'},
			@set.send(:parse_meta,':','foo'),
			'Set#parse_meta should be able to parse default tokens'
		)
		assert_equal(
			{:default => ['foo','bar']},
			@set.send(:parse_meta,':','bar',{:default => ['foo']}),
			'Set#parse_meta should be able to parse default tokens'
		)
	end

	def test_parse_options
		result = @set.send(:parse_html,'hello foo:(bar "baz baz","world",hi qux)')
		assert_equal(
			{'foo' => {:klass => 'Bar',:options => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:meta],
			'Set#parse_html should be able to parse a tag that is not closed'
		)
		assert_equal(
			'hello %%foo%%',
			result[:tmpl],
			'Set#parse_html should be able to parse a tag that is not closed'
		)
	end

	def test_parse_duplicate_tag
		result = @set.send(:parse_html,'hello foo:(bar "baz baz") world foo:(boo)!')
		assert_equal(
			{'foo' => {:klass => 'Boo'}},
			result[:meta],
			'definition tags are overridden by a preceding definition'
		)
		assert_equal(
			'hello %%foo%% world %%foo%%!',
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)
	end

	def test_parse_block_tag
		result = @set.send(:parse_html,<<'_html')
<ul class="sofa-blog" id="foo"><li>hello</li></ul>
_html
		assert_equal(
			{'foo' => {:klass =>'list',:workflow => 'blog',:html => '<li>hello</li>'}},
			result[:meta],
			'Set#parse_html should be able to parse block sofa tags'
		)
		assert_equal(
			<<'_html',
%%foo%%
_html
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)

		result = @set.send(:parse_html,<<'_html')
<ul class="sofa-blog" id="foo">
	<li>hello</li>
</ul>
_html
		assert_equal(
			{'foo' => {:klass =>'list',:workflow => 'blog',:html => "\t<li>hello</li>\n"}},
			result[:meta],
			'Set#parse_html should be able to parse block sofa tags'
		)
		assert_equal(
			<<'_html',
%%foo%%
_html
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)

		result = @set.send(:parse_html,<<'_html')
hello <ul class="sofa-blog" id="foo"><li>hello</li></ul> world
_html
		assert_equal(
			{'foo' => {:klass =>'list',:workflow => 'blog',:html => '<li>hello</li>'}},
			result[:meta],
			'Set#parse_html should be able to parse block sofa tags'
		)
		assert_equal(
			<<'_html',
hello %%foo%% world
_html
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)
	end

	def test_nested_block_tags
		result = @set.send(:parse_html,<<'_html')
<ul class="sofa-blog" id="foo">
	<li>
		<ul class="sofa-blog" id="bar"><li>baz</li></ul>
	</li>
</ul>
_html
		assert_equal(
			{'foo' => {:klass =>'list',:workflow => 'blog',:html => <<'_html'}},
	<li>
		<ul class="sofa-blog" id="bar"><li>baz</li></ul>
	</li>
_html
			result[:meta],
			'Set#parse_html should be able to parse nested block sofa tags'
		)
		assert_equal(
			<<'_html',
%%foo%%
_html
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)
	end

	def test_combination
		result = @set.send(:parse_html,<<'_html')
<html>
	<h1>title:(text 32)</h1>
	<ul id="foo" class="sofa-blog">
		<li>
			subject:(text 64)
			body:(textarea 72*10)
			<ul><li>qux</li></ul>
		</li>
	</ul>
</html>
_html
		assert_equal(
			{
				'title' => {:klass => 'Text',:tokens => ['32']},
				'foo'   => {:klass =>'list',:workflow => 'blog',:html => <<'_html'},
		<li>
			subject:(text 64)
			body:(textarea 72*10)
			<ul><li>qux</li></ul>
		</li>
_html
			},
			result[:meta],
			'Set#parse_html should be able to parse combination of mixed sofa tags'
		)
		assert_equal(
			<<'_html',
<html>
	<h1>%%title%%</h1>
	%%foo%%
</html>
_html
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)
	end

end
