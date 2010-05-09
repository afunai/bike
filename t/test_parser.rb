# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Parser < Test::Unit::TestCase

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
		result = Sofa::Parser.parse_html('hello $(foo = bar "baz baz") world')
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
<h1>$(foo=bar "baz baz")</h1>
<p>$(bar=a b c)</p>
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
		result = Sofa::Parser.parse_html('hello $(foo = bar $(baz=1) baz) world')
		assert_equal(
			{'foo' => {:klass => 'bar',:tokens => ['$(baz=1']}},
			result[:item],
			'Parser.parse_html should not parse nested empty tag'
		)
		assert_equal(
			'hello $(foo) baz) world',
			result[:tmpl],
			'Parser.parse_html[:tmpl] should be a proper template'
		)

		result = Sofa::Parser.parse_html('hello $(foo = bar baz world')
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

		result = Sofa::Parser.parse_html('hello $(foo = bar "baz"world)')
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

		result = Sofa::Parser.parse_html('hello $(foo = bar,"baz")')
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
		result = Sofa::Parser.parse_html('hello $(foo = bar ,"baz baz","world",hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Parser.parse_html should be able to parse a sequence of CSV'
		)
		result = Sofa::Parser.parse_html('hello $(foo = bar "baz baz","world",hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Parser.parse_html should be able to parse a sequence of CSV'
		)
	end

	def test_parse_options_with_spaces
		result = Sofa::Parser.parse_html('hello $(foo = bar world, qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['world','qux']}},
			result[:item],
			'Parser.parse_html should allow spaces after the comma'
		)
		result = Sofa::Parser.parse_html('hello $(foo = bar world ,qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['qux'],:tokens => ['world']}},
			result[:item],
			'Parser.parse_html should not allow spaces before the comma'
		)
		result = Sofa::Parser.parse_html('hello $(foo = bar "baz baz", "world", hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:options => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Parser.parse_html should allow spaces after the comma'
		)

		result = Sofa::Parser.parse_html(<<'_eos')
hello $(foo =
	bar
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
		result = Sofa::Parser.parse_html('hello $(foo = bar ;"baz baz";"world";hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Parser.parse_html should be able to parse a sequence of CSV as [:defaults]'
		)
		result = Sofa::Parser.parse_html('hello $(foo = bar "baz baz";"world";hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Parser.parse_html should be able to parse a sequence of CSV as [:defaults]'
		)
	end

	def test_parse_defaults_with_spaces
		result = Sofa::Parser.parse_html('hello $(foo=bar world; qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['world','qux']}},
			result[:item],
			'Parser.parse_html should allow spaces after the semicolon'
		)
		result = Sofa::Parser.parse_html('hello $(foo=bar world ;qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['qux'],:tokens => ['world']}},
			result[:item],
			'Parser.parse_html should not allow spaces before the semicolon'
		)
		result = Sofa::Parser.parse_html('hello $(foo=bar "baz baz"; "world"; hi qux)')
		assert_equal(
			{'foo' => {:klass => 'bar',:defaults => ['baz baz','world','hi'],:tokens => ['qux']}},
			result[:item],
			'Parser.parse_html should allow spaces after the comma'
		)

		result = Sofa::Parser.parse_html(<<'_eos')
hello $(foo =
	bar
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
		result = Sofa::Parser.parse_html('hello $(foo = bar "baz baz") world $(foo=boo) $(foo)!')
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
					:klass    => 'set-dynamic',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl'.chomp,
<ul class="sofa-blog" id="@(name)">$()</ul>
$(.navi)$(.submit)$(.action_create)
_tmpl
					:item     => {
						'default' => {
							:label => nil,
							:tmpl  => '<li>hello</li>',
							:item  => {},
						},
					},
				},
			},
			result[:item],
			'Parser.parse_html should be able to parse block sofa tags'
		)
		assert_equal(
			'$(foo.message)$(foo)',
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
					:klass    => 'set-dynamic',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl'.chomp,
<ul class="sofa-blog" id="@(name)">
$()</ul>
$(.navi)$(.submit)$(.action_create)
_tmpl
					:item     => {
						'default' => {
							:label => nil,
							:tmpl  => "\t<li>hello</li>\n",
							:item  => {},
						},
					}
				},
			},
			result[:item],
			'Parser.parse_html should be able to parse block sofa tags'
		)
		assert_equal(
			'$(foo.message)$(foo)',
			result[:tmpl],
			'Parser.parse_html[:tmpl] should be a proper template'
		)

		result = Sofa::Parser.parse_html <<'_html'
hello <ul class="sofa-blog" id="foo"><li>hello</li></ul> world
_html
		assert_equal(
			{
				'foo' => {
					:klass    => 'set-dynamic',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl'.chomp,
 <ul class="sofa-blog" id="@(name)">$()</ul>$(.navi)$(.submit)$(.action_create)
_tmpl
					:item     => {
						'default' => {
							:label => nil,
							:tmpl  => '<li>hello</li>',
							:item  => {},
						},
					},
				},
			},
			result[:item],
			'Parser.parse_html should be able to parse block sofa tags'
		)
		assert_equal(
			<<'_html',
hello$(foo.message)$(foo) world
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
			<<'_tmpl',
hello <ul class="not-sofa-blog" id="foo"><li>hello</li></ul> world
_tmpl
			result[:tmpl],
			"Parser.parse_html[:tmpl] should skip a class which does not start with 'sofa'"
		)
	end

	def test_block_tags_with_options
		result = Sofa::Parser.parse_html <<'_html'
hello
	<table class="sofa-blog" id="foo">
		<!-- 1..20 barbaz -->
		<tbody class="body"><!-- qux --><tr><th>$(bar=text)</th><th>$(baz=text)</th></tr></tbody>
	</table>
world
_html
		assert_equal(
			{
				'foo' => {
					:min      => 1,
					:max      => 20,
					:tokens   => ['barbaz'],
					:klass    => 'set-dynamic',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl'.chomp,
	<table class="sofa-blog" id="@(name)">
		<!-- 1..20 barbaz -->
$()	</table>
$(.navi)$(.submit)$(.action_create)
_tmpl
					:item     => {
						'default' => {
							:label => nil,
							:tmpl  => <<'_tmpl',
		<tbody class="body"><!-- qux --><tr><th>$(.a_update)$(bar)</a></th><th>$(baz)$(.hidden)</th></tr></tbody>
_tmpl
							:item  => {
								'bar' => {:klass => 'text'},
								'baz' => {:klass => 'text'},
							},
						},
					},
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
		<tbody class="body"><tr><th>$(bar=text)</th><th>$(baz=text)</th></tr></tbody>
	</table>
world
_html
		assert_equal(
			{
				'foo' => {
					:klass    => 'set-dynamic',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl'.chomp,
	<table class="sofa-blog" id="@(name)">
		<thead><tr><th>BAR</th><th>BAZ</th></tr></thead>
$()	</table>
$(.navi)$(.submit)$(.action_create)
_tmpl
					:item     => {
						'default' => {
							:label => nil,
							:tmpl  => <<'_tmpl',
		<tbody class="body"><tr><th>$(.a_update)$(bar)</a></th><th>$(baz)$(.hidden)</th></tr></tbody>
_tmpl
							:item  => {
								'bar' => {:klass => 'text'},
								'baz' => {:klass => 'text'},
							},
						},
					},
				},
			},
			result[:item],
			'Parser.parse_html should aware of <tbody class="body">'
		)
		assert_equal(
			<<'_tmpl',
hello
$(foo.message)$(foo)world
_tmpl
			result[:tmpl],
			'Parser.parse_html[:tmpl] should be a proper template'
		)
	end

	def test_parse_item_label
		result = Sofa::Parser.parse_html <<'_html'
<ul class="sofa-blog" id="foo"><li title="Greeting">hello</li></ul>
_html
		assert_equal(
			'Greeting',
			result[:item]['foo'][:item]['default'][:label],
			'Parser.parse_html should pick up item labels from title attrs'
		)

		result = Sofa::Parser.parse_html <<'_html'
<ul class="sofa-blog" id="foo"><!-- foo --><li title="Greeting">hello</li></ul>
_html
		assert_equal(
			'Greeting',
			result[:item]['foo'][:item]['default'][:label],
			'Parser.parse_html should pick up item labels from title attrs'
		)

		result = Sofa::Parser.parse_html <<'_html'
<ul class="sofa-blog" id="foo"><!-- foo --><li><div title="Foo">hello</div></li></ul>
_html
		assert_nil(
			result[:item]['foo'][:item]['default'][:label],
			'Parser.parse_html should pick up item labels only from the first tags'
		)
	end

	def test_block_tags_with_nested_tbody
		result = Sofa::Parser.parse_html <<'_html'
hello
	<table class="sofa-blog" id="foo">
		<thead><tr><th>BAR</th><th>BAZ</th></tr></thead>
		<tbody class="body"><tbody><tr><th>$(bar=text)</th><th>$(baz=text)</th></tr></tbody></tbody>
	</table>
world
_html
		assert_equal(
			{
				'foo' => {
					:klass    => 'set-dynamic',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl'.chomp,
	<table class="sofa-blog" id="@(name)">
		<thead><tr><th>BAR</th><th>BAZ</th></tr></thead>
$()	</table>
$(.navi)$(.submit)$(.action_create)
_tmpl
					:item     => {
						'default' => {
							:label => nil,
							:tmpl  => <<'_tmpl',
		<tbody class="body"><tbody><tr><th>$(.a_update)$(bar)</a></th><th>$(baz)$(.hidden)</th></tr></tbody></tbody>
_tmpl
							:item  => {
								'bar' => {:klass => 'text'},
								'baz' => {:klass => 'text'},
							},
						},
					},
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
					:klass    => 'set-dynamic',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl'.chomp,
<ul class="sofa-blog" id="@(name)">
$()</ul>
$(.navi)$(.submit)$(.action_create)
_tmpl
					:item     => {
						'default' => {
							:label => nil,
							:tmpl  => <<'_tmpl',
	<li>
$(bar.message)$(.a_update)$(bar)$(.hidden)</a>	</li>
_tmpl
							:item  => {
								'bar' => {
									:klass    => 'set-dynamic',
									:workflow => 'blog',
									:tmpl     => <<'_tmpl'.chomp,
		<ul class="sofa-blog" id="@(name)">$()</ul>
$(.navi)$(.submit)$(.action_create)
_tmpl
									:item     => {
										'default' => {
											:label => nil,
											:tmpl  => '<li>baz</li>',
											:item  => {},
										},
									},
								},
							},
						},
					},
				},
			},
			result[:item],
			'Parser.parse_html should be able to parse nested block sofa tags'
		)
		assert_equal(
			'$(foo.message)$(foo)',
			result[:tmpl],
			'Parser.parse_html[:tmpl] should be a proper template'
		)
	end

	def test_combination
		result = Sofa::Parser.parse_html <<'_html'
<html>
	<h1>$(title=text 32)</h1>
	<ul id="foo" class="sofa-blog">
		<li>
			$(subject=text 64)
			$(body=textarea 72*10)
			<ul><li>qux</li></ul>
		</li>
	</ul>
</html>
_html
		assert_equal(
			{
				'title' => {:klass => 'text',:tokens => ['32']},
				'foo'   => {
					:klass    => 'set-dynamic',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl'.chomp,
	<ul id="@(name)" class="sofa-blog">
$()	</ul>
$(.navi)$(.submit)$(.action_create)
_tmpl
					:item     => {
						'default' => {
							:label => nil,
							:tmpl  => <<'_tmpl',
		<li>
			$(.a_update)$(subject)</a>
			$(body)$(.hidden)
			<ul><li>qux</li></ul>
		</li>
_tmpl
							:item  => {
								'body' => {
									:width  => 72,
									:height => 10,
									:klass  => 'textarea',
								},
								'subject' => {
									:tokens => ['64'],
									:klass  => 'text',
								},
							},
						},
					},
				},
			},
			result[:item],
			'Parser.parse_html should be able to parse combination of mixed sofa tags'
		)
		assert_equal(
			<<'_tmpl',
<html>
	<h1>$(title)</h1>
$(foo.message)$(foo)</html>
_tmpl
			result[:tmpl],
			'Parser.parse_html[:tmpl] should be a proper template'
		)
	end

	def test_gsub_block
		match = nil
		result = Sofa::Parser.gsub_block('a<div class="foo">bar</div>c','foo') {|open,inner,close|
			match = [open,inner,close]
			'b'
		}
		assert_equal(
			'abc',
			result,
			'Parser.gsub_block should replace tag blocks of the matching class with the given value'
		)
		assert_equal(
			['<div class="foo">','bar','</div>'],
			match,
			'Parser.gsub_block should pass the matching element to its block'
		)

		result = Sofa::Parser.gsub_block('<p><div class="foo">bar</div></p>','foo') {|open,inner,close|
			match = [open,inner,close]
			'b'
		}
		assert_equal(
			'<p>b</p>',
			result,
			'Parser.gsub_block should replace tag blocks of the matching class with the given value'
		)
		assert_equal(
			['<div class="foo">','bar','</div>'],
			match,
			'Parser.gsub_block should pass the matching element to its block'
		)

		result = Sofa::Parser.gsub_block('a<p><div class="foo">bar</div></p>c','foo') {|open,inner,close|
			match = [open,inner,close]
			'b'
		}
		assert_equal(
			'a<p>b</p>c',
			result,
			'Parser.gsub_block should replace tag blocks of the matching class with the given value'
		)
		assert_equal(
			['<div class="foo">','bar','</div>'],
			match,
			'Parser.gsub_block should pass the matching element to its block'
		)
	end

	def _test_gsub_action_tmpl(html)
		result = {}
		html = Sofa::Parser.gsub_action_tmpl(html) {|id,action,*tmpl|
			result[:id]     = id
			result[:action] = action
			result[:tmpl]   = tmpl.join
			'b'
		}
		[result,html]
	end

	def test_gsub_action_tmpl
		result,html = _test_gsub_action_tmpl 'a<div class="foo-navi">Foo</div>c'
		assert_equal(
			{
				:id     => 'foo',
				:action => 'navi',
				:tmpl   => '<div class="foo-navi">Foo</div>',
			},
			result,
			'Parser.gsub_action_tmpl should yield action templates'
		)
		assert_equal(
			'abc',
			html,
			'Parser.gsub_action_tmpl should replace the action template with a value from the block'
		)

		result,html = _test_gsub_action_tmpl 'a<div class="bar foo-navi">Foo</div>c'
		assert_equal(
			{
				:id     => 'foo',
				:action => 'navi',
				:tmpl   => '<div class="bar foo-navi">Foo</div>',
			},
			result,
			'Parser.gsub_action_tmpl should yield action templates'
		)

		result,html = _test_gsub_action_tmpl 'a<div class="bar foo-navi baz">Foo</div>c'
		assert_equal(
			{
				:id     => 'foo',
				:action => 'navi',
				:tmpl   => '<div class="bar foo-navi baz">Foo</div>',
			},
			result,
			'Parser.gsub_action_tmpl should yield action templates'
		)
	end

	def test_gsub_action_tmpl_with_empty_id
		result,html = _test_gsub_action_tmpl 'a<div class="navi">Foo</div>c'
		assert_equal(
			{
				:id     => nil,
				:action => 'navi',
				:tmpl   => '<div class="navi">Foo</div>',
			},
			result,
			'Parser.gsub_action_tmpl should yield action templates'
		)

		result,html = _test_gsub_action_tmpl 'a<div class="foo navi">Foo</div>c'
		assert_equal(
			{
				:id     => nil,
				:action => 'navi',
				:tmpl   => '<div class="foo navi">Foo</div>',
			},
			result,
			'Parser.gsub_action_tmpl should yield action templates'
		)

		result,html = _test_gsub_action_tmpl 'a<div class="foo navi baz">Foo</div>c'
		assert_equal(
			{
				:id     => nil,
				:action => 'navi',
				:tmpl   => '<div class="foo navi baz">Foo</div>',
			},
			result,
			'Parser.gsub_action_tmpl should yield action templates'
		)
	end

	def test_gsub_action_tmpl_with_ambiguous_klass
		result,html = _test_gsub_action_tmpl 'a<div class="not_navi">Foo</div>c'
		assert_equal(
			{},
			result,
			'Parser.gsub_action_tmpl should ignore classes other than action, view, navi or submit'
		)

		result,html = _test_gsub_action_tmpl 'a<div class="navi_bar">Foo</div>c'
		assert_equal(
			{
				:id     => nil,
				:action => 'navi_bar',
				:tmpl   => '<div class="navi_bar">Foo</div>',
			},
			result,
			'Parser.gsub_action_tmpl should yield an action template if the klass looks like special'
		)
	end

	def test_action_tmpl_in_ss
		result = Sofa::Parser.parse_html <<'_html'
<html>
	<ul id="foo" class="sofa-blog">
		<li>$(subject=text)</li>
	</ul>
	<div class="foo-navi">bar</div>
</html>
_html
		assert_equal(
			<<'_tmpl',
	<div class="foo-navi">bar</div>
_tmpl
			result[:item]['foo'][:tmpl_navi],
			'Parser.parse_html should parse action templates in the html'
		)
		assert_equal(
			<<'_tmpl',
<html>
$(foo.message)$(foo)$(foo.navi)</html>
_tmpl
			result[:tmpl],
			'Parser.parse_html should replace action templates with proper tags'
		)
	end

	def test_action_tmpl_in_ss_with_nil_id
		result = Sofa::Parser.parse_html <<'_html'
<html>
	<ul id="main" class="sofa-blog">
		<li>$(subject=text)</li>
	</ul>
	<div class="navi">bar</div>
</html>
_html
		assert_equal(
			<<'_tmpl',
	<div class="navi">bar</div>
_tmpl
			result[:item]['main'][:tmpl_navi],
			"Parser.parse_html should set action templates to item['main'] by default"
		)
		assert_equal(
			<<'_tmpl',
<html>
$(main.message)$(main)$(main.navi)</html>
_tmpl
			result[:tmpl],
			"Parser.parse_html should set action templates to item['main'] by default"
		)
	end

	def test_action_tmpl_in_ss_with_non_existent_id
		result = Sofa::Parser.parse_html <<'_html'
<html>
	<ul id="main" class="sofa-blog">
		<li>$(subject=text)</li>
	</ul>
	<div class="non_existent-navi">bar</div>
</html>
_html
		assert_nil(
			result[:item]['non_existent'],
			'Parser.parse_html should ignore the action template without a corresponding SD'
		)
		assert_equal(
			<<'_tmpl',
<html>
$(main.message)$(main)	<div class="non_existent-navi">bar</div>
</html>
_tmpl
			result[:tmpl],
			'Parser.parse_html should ignore the action template without a corresponding SD'
		)
	end

	def test_action_tmpl_in_ss_with_nested_action_tmpl
		result = Sofa::Parser.parse_html <<'_html'
<html>
	<ul id="foo" class="sofa-blog">
		<li>$(subject=text)</li>
	</ul>
	<div class="foo-navi"><span class="navi_prev">prev</span></div>
</html>
_html
		assert_equal(
			<<'_html',
	<div class="foo-navi">$(.navi_prev)</div>
_html
			result[:item]['foo'][:tmpl_navi],
			'Parser.parse_html should parse nested action templates'
		)
		assert_equal(
			'<span class="navi_prev">prev</span>',
			result[:item]['foo'][:tmpl_navi_prev],
			'Parser.parse_html should parse nested action templates'
		)

		result = Sofa::Parser.parse_html <<'_html'
<html>
	<ul id="foo" class="sofa-blog">
		<li>$(subject=text)</li>
	</ul>
	<div class="foo-navi"><span class="bar-navi_prev">prev</span></div>
</html>
_html
		assert_equal(
			'<span class="bar-navi_prev">prev</span>',
			result[:item]['foo'][:tmpl_navi_prev],
			'Parser.parse_html should ignore the id of a nested action template'
		)
	end

	def test_action_tmpl_in_sd
		result = Sofa::Parser.parse_html <<'_html'
<ul id="foo" class="sofa-blog">
	<li class="body">$(text)</li>
	<div class="navi">bar</div>
</ul>
_html
		assert_equal(
			<<'_html',
	<div class="navi">bar</div>
_html
			result[:item]['foo'][:tmpl_navi],
			'Parser.parse_html should parse action templates in sd[:tmpl]'
		)
		assert_match(
			%r{\$\(\.navi\)},
			result[:item]['foo'][:tmpl],
			'Parser.parse_html should parse action templates in sd[:tmpl]'
		)
	end

	def test_action_tmpl_in_sd_with_nested_action_tmpl
		result = Sofa::Parser.parse_html <<'_html'
<ul id="foo" class="sofa-blog">
	<li class="body">$(text)</li>
	<div class="navi"><span class="navi_prev">prev</span></div>
</ul>
_html
		assert_equal(
			<<'_html',
	<div class="navi">$(.navi_prev)</div>
_html
			result[:item]['foo'][:tmpl_navi],
			'Parser.parse_html should parse nested action templates in sd[:tmpl]'
		)
		assert_equal(
			'<span class="navi_prev">prev</span>',
			result[:item]['foo'][:tmpl_navi_prev],
			'Parser.parse_html should parse nested action templates in sd[:tmpl]'
		)
	end

	def test_supplement_menus_in_sd
		result = Sofa::Parser.parse_html <<'_html'
<ul id="foo" class="sofa-blog">
	<li class="body">$(text)</li>
</ul>
_html
		assert_match(
			/\$\(\.navi\)/,
			result[:item]['foo'][:tmpl],
			'Parser.parse_html should supplement sd[:tmpl] with default menus'
		)

		result = Sofa::Parser.parse_html <<'_html'
<ul id="foo" class="sofa-blog">
	<div class="navi">bar</div>
	<li class="body">$(text)</li>
</ul>
_html
		assert_no_match(
			/\$\(\.navi\).*\$\(\.navi\)/m,
			result[:item]['foo'][:tmpl],
			'Parser.parse_html should not supplement sd[:tmpl] when it already has the menu'
		)

		result = Sofa::Parser.parse_html <<'_html'
<div class="foo-navi">bar</div>
<ul id="foo" class="sofa-blog">
	<li class="body">$(text)</li>
</ul>
_html
		assert_no_match(
			/\$\(\.navi\)/,
			result[:item]['foo'][:tmpl],
			'Parser.parse_html should not supplement sd[:tmpl] when it already has the menu'
		)
	end

end
