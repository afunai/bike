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
			{:klass => 'foo',:tokens => ['bar','baz']},
			@set.send(:parse_tokens,StringScanner.new('foo bar baz')),
			'Set#parse_tokens should be able to parse unquoted tokens into array'
		)
		assert_equal(
			{:klass => 'foo',:tokens => ['bar','baz baz']},
			@set.send(:parse_tokens,StringScanner.new('foo "bar" "baz baz"')),
			'Set#parse_tokens should be able to parse quoted tokens'
		)
		assert_equal(
			{:klass => 'foo',:tokens => ['bar','baz']},
			@set.send(:parse_tokens,StringScanner.new("foo 'bar' baz")),
			'Set#parse_tokens should be able to parse quoted tokens'
		)

		assert_equal(
			{:klass => 'foo',:tokens => ['bar','baz']},
			@set.send(:parse_tokens,StringScanner.new("foo 'bar' baz) qux")),
			'Set#parse_tokens should stop scanning at an ending bracket'
		)
		assert_equal(
			{:klass => 'foo',:tokens => ['bar (bar?)','baz']},
			@set.send(:parse_tokens,StringScanner.new("foo 'bar (bar?)' baz) qux")),
			'Set#parse_tokens should ignore brackets inside quoted tokens'
		)
	end

	def test_parse_empty_tag
		result = @set.send(:parse_html,'hello foo:(bar "baz baz") world')
		assert_equal(
			{'foo' => {:klass => 'bar',:tokens => ['baz baz']}},
			result[:item],
			'Set#parse_html should be able to parse empty sofa tags'
		)
		assert_equal(
			'hello $(foo) world',
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)

		result = @set.send(:parse_html,<<'_html')
<h1>foo:(bar "baz baz")</h1>
<p>bar:(a b c)</p>
_html
		assert_equal(
			{
				'foo' => {:klass => 'bar',:tokens => ['baz baz']},
				'bar' => {:klass => 'a',:tokens => ['b','c']},
			},
			result[:item],
			'Set#parse_html should be able to parse empty sofa tags'
		)
		assert_equal(
			<<'_html',
<h1>$(foo)</h1>
<p>$(bar)</p>
_html
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)
	end

	def test_obscure_markup
		result = @set.send(:parse_html,'hello foo:(bar baz:(1) baz) world')
		assert_equal(
			{'foo' => {:klass => 'bar',:default => '(1',:tokens => ['baz']}},
			result[:item],
			'Set#parse_html should not parse nested empty tag'
		)
		assert_equal(
			'hello $(foo) baz) world',
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)

		result = @set.send(:parse_html,'hello foo:(bar baz world')
		assert_equal(
			{'foo' => {:klass => 'bar',:tokens => ['baz','world']}},
			result[:item],
			'Set#parse_html should be able to parse a tag that is not closed'
		)
		assert_equal(
			'hello $(foo)',
			result[:tmpl],
			'Set#parse_html should be able to parse a tag that is not closed'
		)

		result = @set.send(:parse_html,'hello foo:(bar "baz"world)')
		assert_equal(
			{'foo' => {:klass => 'bar',:tokens => ['baz','world']}},
			result[:item],
			'Set#parse_html should be able to parse tokens without a delimiter'
		)
		assert_equal(
			'hello $(foo)',
			result[:tmpl],
			'Set#parse_html should be able to parse tokens without a delimiter'
		)

		result = @set.send(:parse_html,'hello foo:(bar,"baz")')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['baz']}},
			result[:item],
			'The first token should be regarded as [:klass]'
		)
	end

	def test_parse_token
		assert_equal(
			{:klass => 'foo'},
			@set.send(:parse_token,nil,'foo',{}),
			'The first token should be regarded as [:klass]'
		)
		assert_equal(
			{:klass => 'foo'},
			@set.send(:parse_token,nil,'foo',{}),
			'The first token should be regarded as [:klass]'
		)

		assert_equal(
			{:klass => 'foo',:width => 160,:height => 120},
			@set.send(:parse_token,nil,'160*120',{:klass => 'foo'}),
			'Set#parse_token should be able to parse dimension tokens'
		)
		assert_equal(
			{:klass => 'foo',:min => 1,:max => 32},
			@set.send(:parse_token,nil,'1..32',{:klass => 'foo'}),
			'Set#parse_token should be able to parse range tokens'
		)

		assert_equal(
			{:klass => 'foo',:options => ['foo']},
			@set.send(:parse_token,',','foo',{:klass => 'foo'}),
			'Set#parse_token should be able to parse option tokens'
		)
		assert_equal(
			{:klass => 'foo',:options => ['foo','bar']},
			@set.send(:parse_token,',','bar',{:klass => 'foo',:options => ['foo']}),
			'Set#parse_token should be able to parse option tokens'
		)

		assert_equal(
			{:klass => 'foo',:default => 'bar'},
			@set.send(:parse_token,':','bar',{:klass => 'foo'}),
			'Set#parse_token should be able to parse default tokens'
		)
		assert_equal(
			{:klass => 'foo',:defaults => ['bar','baz']},
			@set.send(:parse_token,';','baz',{:klass => 'foo',:defaults => ['bar']}),
			'Set#parse_token should be able to parse defaults tokens'
		)
	end

	def test_parse_options
		result = @set.send(:parse_html,'hello foo:(bar ,"baz baz","world",hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Set#parse_html should be able to parse a sequence of CSV'
		)
		result = @set.send(:parse_html,'hello foo:(bar "baz baz","world",hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Set#parse_html should be able to parse a sequence of CSV'
		)
	end

	def test_parse_options_with_spaces
		result = @set.send(:parse_html,'hello foo:(bar world, qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['world','qux']}},
			result[:item],
			'Set#parse_html should allow spaces after the comma'
		)
		result = @set.send(:parse_html,'hello foo:(bar world ,qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['qux'],:tokens => ['world']}},
			result[:item],
			'Set#parse_html should not allow spaces before the comma'
		)
		result = @set.send(:parse_html,'hello foo:(bar "baz baz", "world", hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Set#parse_html should allow spaces after the comma'
		)

		result = @set.send(:parse_html,<<'_eos')
hello foo:(bar
	"baz baz",
	"world",
	hi
	qux)
_eos
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Set#parse_html should allow spaces after the comma'
		)
	end

	def test_parse_defaults
		result = @set.send(:parse_html,'hello foo:(bar ;"baz baz";"world";hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Set#parse_html should be able to parse a sequence of CSV as [:defaults]'
		)
		result = @set.send(:parse_html,'hello foo:(bar "baz baz";"world";hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Set#parse_html should be able to parse a sequence of CSV as [:defaults]'
		)
	end

	def test_parse_defaults_with_spaces
		result = @set.send(:parse_html,'hello foo:(bar world; qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['world','qux']}},
			result[:item],
			'Set#parse_html should allow spaces after the semicolon'
		)
		result = @set.send(:parse_html,'hello foo:(bar world ;qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['qux'],:tokens => ['world']}},
			result[:item],
			'Set#parse_html should not allow spaces before the semicolon'
		)
		result = @set.send(:parse_html,'hello foo:(bar "baz baz"; "world"; hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Set#parse_html should allow spaces after the comma'
		)

		result = @set.send(:parse_html,<<'_eos')
hello foo:(bar
	"baz baz";
	"world";
	hi
	qux)
_eos
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Set#parse_html should allow spaces after the comma'
		)
	end

	def test_parse_duplicate_tag
		result = @set.send(:parse_html,'hello foo:(bar "baz baz") world foo:(boo) $(foo)!')
		assert_equal(
			{'foo' => {:klass => 'boo'}},
			result[:item],
			'definition tags are overridden by a preceding definition'
		)
		assert_equal(
			'hello $(foo) world $(foo) $(foo)!',
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)
	end

	def test_parse_block_tag
		result = @set.send(:parse_html,<<'_html')
<ul class="sofa-blog" id="foo"><li>hello</li></ul>
_html
		assert_equal(
			{
				'foo' => {
					:klass    => 'list',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl',
<ul class="sofa-blog" id="foo">$()</ul>
_tmpl
					:set_html => '<li>hello</li>',
				}
			},
			result[:item],
			'Set#parse_html should be able to parse block sofa tags'
		)
		assert_equal(
			<<'_html',
$(foo)
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
			{
				'foo' => {
					:klass    => 'list',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl',
<ul class="sofa-blog" id="foo">$()</ul>
_tmpl
					:set_html => "\t<li>hello</li>\n",
				},
			},
			result[:item],
			'Set#parse_html should be able to parse block sofa tags'
		)
		assert_equal(
			<<'_html',
$(foo)
_html
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)

		result = @set.send(:parse_html,<<'_html')
hello <ul class="sofa-blog" id="foo"><li>hello</li></ul> world
_html
		assert_equal(
			{
				'foo' => {
					:klass    => 'list',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl',
<ul class="sofa-blog" id="foo">$()</ul>
_tmpl
					:set_html => '<li>hello</li>',
				},
			},
			result[:item],
			'Set#parse_html should be able to parse block sofa tags'
		)
		assert_equal(
			<<'_html',
hello $(foo) world
_html
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)
	end

	def test_block_tags_with_tbody
		result = @set.send(:parse_html,<<'_html')
hello
	<table class="sofa-blog" id="foo">
		<thead><tr><th>BAR</th><th>BAZ</th></tr></thead>
		<tbody><tr><th>bar:(text)</th><th>baz:(text)</th></tr></tbody>
	</table>
world
_html
		assert_equal(
			{
				'foo' => {
					:klass    => 'list',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl',
<table class="sofa-blog" id="foo">		<thead><tr><th>BAR</th><th>BAZ</th></tr></thead>
$()</table>
_tmpl
					:set_html => <<'_tmpl',
		<tbody><tr><th>bar:(text)</th><th>baz:(text)</th></tr></tbody>
_tmpl
				},
			},
			result[:item],
			'Set#parse_html should aware of <tbody>'
		)
		assert_equal(
			<<'_html',
hello
	$(foo)
world
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
			{
				'foo' => {
					:klass    => 'list',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl',
<ul class="sofa-blog" id="foo">$()</ul>
_tmpl
					:set_html => <<'_html',
	<li>
		<ul class="sofa-blog" id="bar"><li>baz</li></ul>
	</li>
_html
				},
			},
			result[:item],
			'Set#parse_html should be able to parse nested block sofa tags'
		)
		assert_equal(
			<<'_html',
$(foo)
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
				'title' => {:klass => 'text',:tokens => ['32']},
				'foo'   => {
					:klass => 'list',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl',
<ul id="foo" class="sofa-blog">$()</ul>
_tmpl
					:set_html => <<'_html',
		<li>
			subject:(text 64)
			body:(textarea 72*10)
			<ul><li>qux</li></ul>
		</li>
_html
				},
			},
			result[:item],
			'Set#parse_html should be able to parse combination of mixed sofa tags'
		)
		assert_equal(
			<<'_html',
<html>
	<h1>$(title)</h1>
	$(foo)
</html>
_html
			result[:tmpl],
			'Set#parse_html[:tmpl] should be a proper template'
		)
	end

end
