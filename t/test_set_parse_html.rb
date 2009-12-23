# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Set_Parse_HTML < Test::Unit::TestCase

	def setup
	end

	def teardown
	end

	def test_scan_tokens
		assert_equal(
			{:tokens => ['foo','bar','baz']},
			Sofa::Parser.scan_tokens(StringScanner.new('foo bar baz')),
			'Parser.scan_tokens should be able to parse unquoted tokens into array'
		)
		assert_equal(
			{:tokens => ['foo','bar','baz baz']},
			Sofa::Parser.scan_tokens(StringScanner.new('foo "bar" "baz baz"')),
			'Parser.scan_tokens should be able to parse quoted tokens'
		)
		assert_equal(
			{:tokens => ['foo','bar','baz']},
			Sofa::Parser.scan_tokens(StringScanner.new("foo 'bar' baz")),
			'Parser.scan_tokens should be able to parse quoted tokens'
		)

		assert_equal(
			{:tokens => ['foo','bar','baz']},
			Sofa::Parser.scan_tokens(StringScanner.new("foo 'bar' baz) qux")),
			'Parser.scan_tokens should stop scanning at an ending bracket'
		)
		assert_equal(
			{:tokens => ['foo','bar (bar?)','baz']},
			Sofa::Parser.scan_tokens(StringScanner.new("foo 'bar (bar?)' baz) qux")),
			'Parser.scan_tokens should ignore brackets inside quoted tokens'
		)
	end

	def test_parse_empty_tag
		result = Sofa::Parser.parse_html('hello foo:(bar "baz baz") world')
		assert_equal(
			{'foo' => {:klass => 'bar',:tokens => ['baz baz']}},
			result[:item],
			'Parser.parse_html should be able to parse empty sofa tags'
		)
		assert_equal(
			'hello $(foo) world',
			result[:tmpl],
			'Parser.parse_html[:tmpl] should be a proper template'
		)

		result = Sofa::Parser.parse_html <<'_html'
<h1>foo:(bar "baz baz")</h1>
<p>bar:(a b c)</p>
_html
		assert_equal(
			{
				'foo' => {:klass => 'bar',:tokens => ['baz baz']},
				'bar' => {:klass => 'a',:tokens => ['b','c']},
			},
			result[:item],
			'Parser.parse_html should be able to parse empty sofa tags'
		)
		assert_equal(
			<<'_html',
<h1>$(foo)</h1>
<p>$(bar)</p>
_html
			result[:tmpl],
			'Parser.parse_html[:tmpl] should be a proper template'
		)
	end

	def test_obscure_markup
		result = Sofa::Parser.parse_html('hello foo:(bar baz:(1) baz) world')
		assert_equal(
			{'foo' => {:klass => 'bar',:default => '(1',:tokens => ['baz']}},
			result[:item],
			'Parser.parse_html should not parse nested empty tag'
		)
		assert_equal(
			'hello $(foo) baz) world',
			result[:tmpl],
			'Parser.parse_html[:tmpl] should be a proper template'
		)

		result = Sofa::Parser.parse_html('hello foo:(bar baz world')
		assert_equal(
			{'foo' => {:klass => 'bar',:tokens => ['baz','world']}},
			result[:item],
			'Parser.parse_html should be able to parse a tag that is not closed'
		)
		assert_equal(
			'hello $(foo)',
			result[:tmpl],
			'Parser.parse_html should be able to parse a tag that is not closed'
		)

		result = Sofa::Parser.parse_html('hello foo:(bar "baz"world)')
		assert_equal(
			{'foo' => {:klass => 'bar',:tokens => ['baz','world']}},
			result[:item],
			'Parser.parse_html should be able to parse tokens without a delimiter'
		)
		assert_equal(
			'hello $(foo)',
			result[:tmpl],
			'Parser.parse_html should be able to parse tokens without a delimiter'
		)

		result = Sofa::Parser.parse_html('hello foo:(bar,"baz")')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['baz']}},
			result[:item],
			'The first token should be regarded as [:klass]'
		)
	end

	def test_parse_token
		assert_equal(
			{:width => 160,:height => 120},
			Sofa::Parser.parse_token(nil,'160*120',{}),
			'Parser.parse_token should be able to parse dimension tokens'
		)
		assert_equal(
			{:min => 1,:max => 32},
			Sofa::Parser.parse_token(nil,'1..32',{}),
			'Parser.parse_token should be able to parse range tokens'
		)
		assert_equal(
			{:max => 32},
			Sofa::Parser.parse_token(nil,'..32',{}),
			'Parser.parse_token should be able to parse partial range tokens'
		)
		assert_equal(
			{:min => 1},
			Sofa::Parser.parse_token(nil,'1..',{}),
			'Parser.parse_token should be able to parse partial range tokens'
		)
		assert_equal(
			{:min => -32,:max => -1},
			Sofa::Parser.parse_token(nil,'-32..-1',{}),
			'Parser.parse_token should be able to parse minus range tokens'
		)

		assert_equal(
			{:options => ['foo']},
			Sofa::Parser.parse_token(',','foo',{}),
			'Parser.parse_token should be able to parse option tokens'
		)
		assert_equal(
			{:options => ['foo','bar']},
			Sofa::Parser.parse_token(',','bar',{:options => ['foo']}),
			'Parser.parse_token should be able to parse option tokens'
		)

		assert_equal(
			{:default => 'bar'},
			Sofa::Parser.parse_token(':','bar',{}),
			'Parser.parse_token should be able to parse default tokens'
		)
		assert_equal(
			{:defaults => ['bar','baz']},
			Sofa::Parser.parse_token(';','baz',{:defaults => ['bar']}),
			'Parser.parse_token should be able to parse defaults tokens'
		)
	end

	def test_parse_options
		result = Sofa::Parser.parse_html('hello foo:(bar ,"baz baz","world",hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Parser.parse_html should be able to parse a sequence of CSV'
		)
		result = Sofa::Parser.parse_html('hello foo:(bar "baz baz","world",hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Parser.parse_html should be able to parse a sequence of CSV'
		)
	end

	def test_parse_options_with_spaces
		result = Sofa::Parser.parse_html('hello foo:(bar world, qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['world','qux']}},
			result[:item],
			'Parser.parse_html should allow spaces after the comma'
		)
		result = Sofa::Parser.parse_html('hello foo:(bar world ,qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['qux'],:tokens => ['world']}},
			result[:item],
			'Parser.parse_html should not allow spaces before the comma'
		)
		result = Sofa::Parser.parse_html('hello foo:(bar "baz baz", "world", hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Parser.parse_html should allow spaces after the comma'
		)

		result = Sofa::Parser.parse_html(<<'_eos')
hello foo:(bar
	"baz baz",
	"world",
	hi
	qux)
_eos
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Parser.parse_html should allow spaces after the comma'
		)
	end

	def test_parse_defaults
		result = Sofa::Parser.parse_html('hello foo:(bar ;"baz baz";"world";hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Parser.parse_html should be able to parse a sequence of CSV as [:defaults]'
		)
		result = Sofa::Parser.parse_html('hello foo:(bar "baz baz";"world";hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Parser.parse_html should be able to parse a sequence of CSV as [:defaults]'
		)
	end

	def test_parse_defaults_with_spaces
		result = Sofa::Parser.parse_html('hello foo:(bar world; qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['world','qux']}},
			result[:item],
			'Parser.parse_html should allow spaces after the semicolon'
		)
		result = Sofa::Parser.parse_html('hello foo:(bar world ;qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['qux'],:tokens => ['world']}},
			result[:item],
			'Parser.parse_html should not allow spaces before the semicolon'
		)
		result = Sofa::Parser.parse_html('hello foo:(bar "baz baz"; "world"; hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Parser.parse_html should allow spaces after the comma'
		)

		result = Sofa::Parser.parse_html(<<'_eos')
hello foo:(bar
	"baz baz";
	"world";
	hi
	qux)
_eos
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Parser.parse_html should allow spaces after the comma'
		)
	end

	def test_parse_duplicate_tag
		result = Sofa::Parser.parse_html('hello foo:(bar "baz baz") world foo:(boo) $(foo)!')
		assert_equal(
			{'foo' => {:klass => 'boo'}},
			result[:item],
			'definition tags are overridden by a preceding definition'
		)
		assert_equal(
			'hello $(foo) world $(foo) $(foo)!',
			result[:tmpl],
			'Parser.parse_html[:tmpl] should be a proper template'
		)
	end

	def test_scan_inner_html
		s = StringScanner.new 'bar</foo>bar'
		inner_html,close_tag = Sofa::Parser.scan_inner_html(s,'foo')
		assert_equal(
			'bar',
			inner_html,
			'Parser.scan_inner_html should extract the inner html from the scanner'
		)
		assert_equal(
			'</foo>',
			close_tag,
			'Parser.scan_inner_html should extract the inner html from the scanner'
		)

		s = StringScanner.new '<foo>bar</foo></foo>'
		inner_html,close_tag = Sofa::Parser.scan_inner_html(s,'foo')
		assert_equal(
			'<foo>bar</foo>',
			inner_html,
			'Parser.scan_inner_html should be aware of nested tags'
		)

		s = StringScanner.new "baz\n\t<foo>bar</foo>\n</foo>"
		inner_html,close_tag = Sofa::Parser.scan_inner_html(s,'foo')
		assert_equal(
			"baz\n\t<foo>bar</foo>\n",
			inner_html,
			'Parser.scan_inner_html should be aware of nested tags'
		)
	end

	def test_parse_block_tag
		result = Sofa::Parser.parse_html <<'_html'
<ul class="sofa-blog" id="foo"><li>hello</li></ul>
_html
		assert_equal(
			{
				'foo' => {
					:klass     => 'set-dynamic',
					:workflow  => 'blog',
					:tmpl      => <<'_tmpl',
<ul class="sofa-blog" id="@(name)">$()</ul>
_tmpl
					:item_html => '<li>hello</li>',
				}
			},
			result[:item],
			'Parser.parse_html should be able to parse block sofa tags'
		)
		assert_equal(
			'$(foo)',
			result[:tmpl],
			'Parser.parse_html[:tmpl] should be a proper template'
		)

		result = Sofa::Parser.parse_html <<'_html'
<ul class="sofa-blog" id="foo">
	<li>hello</li>
</ul>
_html
		assert_equal(
			{
				'foo' => {
					:klass     => 'set-dynamic',
					:workflow  => 'blog',
					:tmpl      => <<'_tmpl',
<ul class="sofa-blog" id="@(name)">
$()</ul>
_tmpl
					:item_html => "\t<li>hello</li>\n",
				},
			},
			result[:item],
			'Parser.parse_html should be able to parse block sofa tags'
		)
		assert_equal(
			'$(foo)',
			result[:tmpl],
			'Parser.parse_html[:tmpl] should be a proper template'
		)

		result = Sofa::Parser.parse_html <<'_html'
hello <ul class="sofa-blog" id="foo"><li>hello</li></ul> world
_html
		assert_equal(
			{
				'foo' => {
					:klass     => 'set-dynamic',
					:workflow  => 'blog',
					:tmpl      => <<'_tmpl'.chomp,
 <ul class="sofa-blog" id="@(name)">$()</ul>
_tmpl
					:item_html => '<li>hello</li>',
				},
			},
			result[:item],
			'Parser.parse_html should be able to parse block sofa tags'
		)
		assert_equal(
			<<'_html',
hello$(foo) world
_html
			result[:tmpl],
			'Parser.parse_html[:tmpl] should be a proper template'
		)
	end

	def test_look_a_like_block_tag
		result = Sofa::Parser.parse_html <<'_html'
hello <ul class="not-sofa-blog" id="foo"><li>hello</li></ul> world
_html
		assert_equal(
			<<'_html',
hello <ul class="not-sofa-blog" id="foo"><li>hello</li></ul> world
_html
			result[:tmpl],
			"Parser.parse_html[:tmpl] should skip a class which does not start with 'sofa'"
		)
	end

	def test_block_tags_with_options
		result = Sofa::Parser.parse_html <<'_html'
hello
	<table class="sofa-blog" id="foo">
		<!-- 1..20 barbaz -->
		<tbody class="body"><!-- qux --><tr><th>bar:(text)</th><th>baz:(text)</th></tr></tbody>
	</table>
world
_html
		assert_equal(
			{
				'foo' => {
					:min       => 1,
					:max       => 20,
					:tokens    => ['barbaz'],
					:klass     => 'set-dynamic',
					:workflow  => 'blog',
					:tmpl      => <<'_tmpl',
	<table class="sofa-blog" id="@(name)">
		<!-- 1..20 barbaz -->
$()	</table>
_tmpl
					:item_html => <<'_html',
		<tbody class="body"><!-- qux --><tr><th>bar:(text)</th><th>baz:(text)</th></tr></tbody>
_html
				},
			},
			result[:item],
			'Parser.parse_html should aware of <tbody class="body">'
		)
	end

	def test_block_tags_with_tbody
		result = Sofa::Parser.parse_html <<'_html'
hello
	<table class="sofa-blog" id="foo">
		<thead><tr><th>BAR</th><th>BAZ</th></tr></thead>
		<tbody class="body"><tr><th>bar:(text)</th><th>baz:(text)</th></tr></tbody>
	</table>
world
_html
		assert_equal(
			{
				'foo' => {
					:klass     => 'set-dynamic',
					:workflow  => 'blog',
					:tmpl      => <<'_tmpl',
	<table class="sofa-blog" id="@(name)">
		<thead><tr><th>BAR</th><th>BAZ</th></tr></thead>
$()	</table>
_tmpl
					:item_html => <<'_html',
		<tbody class="body"><tr><th>bar:(text)</th><th>baz:(text)</th></tr></tbody>
_html
				},
			},
			result[:item],
			'Parser.parse_html should aware of <tbody class="body">'
		)
		assert_equal(
			<<'_html',
hello
$(foo)world
_html
			result[:tmpl],
			'Parser.parse_html[:tmpl] should be a proper template'
		)
	end

	def test_block_tags_with_nested_tbody
		result = Sofa::Parser.parse_html <<'_html'
hello
	<table class="sofa-blog" id="foo">
		<thead><tr><th>BAR</th><th>BAZ</th></tr></thead>
		<tbody class="body"><tbody><tr><th>bar:(text)</th><th>baz:(text)</th></tr></tbody></tbody>
	</table>
world
_html
		assert_equal(
			{
				'foo' => {
					:klass     => 'set-dynamic',
					:workflow  => 'blog',
					:tmpl      => <<'_tmpl',
	<table class="sofa-blog" id="@(name)">
		<thead><tr><th>BAR</th><th>BAZ</th></tr></thead>
$()	</table>
_tmpl
					:item_html => <<'_html',
		<tbody class="body"><tbody><tr><th>bar:(text)</th><th>baz:(text)</th></tr></tbody></tbody>
_html
				},
			},
			result[:item],
			'Parser.parse_html should aware of nested <tbody class="body">'
		)
	end

	def test_nested_block_tags
		result = Sofa::Parser.parse_html <<'_html'
<ul class="sofa-blog" id="foo">
	<li>
		<ul class="sofa-blog" id="bar"><li>baz</li></ul>
	</li>
</ul>
_html
		assert_equal(
			{
				'foo' => {
					:klass     => 'set-dynamic',
					:workflow  => 'blog',
					:tmpl      => <<'_tmpl',
<ul class="sofa-blog" id="@(name)">
$()</ul>
_tmpl
					:item_html => <<'_html',
	<li>
		<ul class="sofa-blog" id="bar"><li>baz</li></ul>
	</li>
_html
				},
			},
			result[:item],
			'Parser.parse_html should be able to parse nested block sofa tags'
		)
		assert_equal(
			'$(foo)',
			result[:tmpl],
			'Parser.parse_html[:tmpl] should be a proper template'
		)
	end

	def test_combination
		result = Sofa::Parser.parse_html <<'_html'
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
					:klass     => 'set-dynamic',
					:workflow  => 'blog',
					:tmpl      => <<'_tmpl',
	<ul id="@(name)" class="sofa-blog">
$()	</ul>
_tmpl
					:item_html => <<'_html',
		<li>
			subject:(text 64)
			body:(textarea 72*10)
			<ul><li>qux</li></ul>
		</li>
_html
				},
			},
			result[:item],
			'Parser.parse_html should be able to parse combination of mixed sofa tags'
		)
		assert_equal(
			<<'_html',
<html>
	<h1>$(title)</h1>
$(foo)</html>
_html
			result[:tmpl],
			'Parser.parse_html[:tmpl] should be a proper template'
		)
	end

end
