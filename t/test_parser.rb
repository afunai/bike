# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class TC_Parser < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_scan_tokens
    assert_equal(
      {:tokens => ['foo', 'bar', 'baz']},
      Bike::Parser.scan_tokens(StringScanner.new('foo bar baz')),
      'Parser.scan_tokens should be able to parse unquoted tokens into array'
    )
    assert_equal(
      {:tokens => ['foo', 'bar', 'baz baz']},
      Bike::Parser.scan_tokens(StringScanner.new('foo "bar" "baz baz"')),
      'Parser.scan_tokens should be able to parse quoted tokens'
    )
    assert_equal(
      {:tokens => ['foo', 'bar', 'baz']},
      Bike::Parser.scan_tokens(StringScanner.new("foo 'bar' baz")),
      'Parser.scan_tokens should be able to parse quoted tokens'
    )

    assert_equal(
      {:tokens => ['foo', 'bar', 'baz']},
      Bike::Parser.scan_tokens(StringScanner.new("foo 'bar' baz) qux")),
      'Parser.scan_tokens should stop scanning at an ending bracket'
    )
    assert_equal(
      {:tokens => ['foo', 'bar (bar?)', 'baz']},
      Bike::Parser.scan_tokens(StringScanner.new("foo 'bar (bar?)' baz) qux")),
      'Parser.scan_tokens should ignore brackets inside quoted tokens'
    )
  end

  def test_parse_empty_tag
    result = Bike::Parser.parse_html('hello $(foo = bar "baz baz") world')
    assert_equal(
      {'foo' => {:klass => 'bar', :tokens => ['baz baz']}},
      result[:item],
      'Parser.parse_html should be able to parse empty bike tags'
    )
    assert_equal(
      {:index => 'hello $(foo) world'},
      result[:tmpl],
      'Parser.parse_html[:tmpl] should be a proper template'
    )

    result = Bike::Parser.parse_html <<'_html'
<h1>$(foo=bar "baz baz")</h1>
<p>$(bar=a b c)</p>
_html
    assert_equal(
      {
        'foo' => {:klass => 'bar', :tokens => ['baz baz']},
        'bar' => {:klass => 'a', :tokens => ['b', 'c']},
      },
      result[:item],
      'Parser.parse_html should be able to parse empty bike tags'
    )
    assert_equal(
      {:index => <<'_html'},
<h1>$(foo)</h1>
<p>$(bar)</p>
_html
      result[:tmpl],
      'Parser.parse_html[:tmpl] should be a proper template'
    )
  end

  def test_parse_empty_tag_in_comment
    html = 'hello <!-- $(foo = bar "baz baz") --> world'
    result = Bike::Parser.parse_html html
    assert_equal(
      {},
      result[:item],
      'Parser.parse_html should skip bike tags in a comment'
    )
    assert_equal(
      {:index => html},
      result[:tmpl],
      'Parser.parse_html should skip bike tags in a comment'
    )

    html = '<script><![CDATA[ $(foo = bar "baz baz") ]]></script>'
    result = Bike::Parser.parse_html html
    assert_equal(
      {},
      result[:item],
      'Parser.parse_html should skip bike tags in a comment'
    )
    assert_equal(
      {:index => html},
      result[:tmpl],
      'Parser.parse_html should skip bike tags in a comment'
    )
  end

  def test_obscure_markup
    result = Bike::Parser.parse_html('hello $(foo = bar $(baz=1) baz) world')
    assert_equal(
      {'foo' => {:klass => 'bar', :tokens => ['$(baz=1']}},
      result[:item],
      'Parser.parse_html should not parse nested empty tag'
    )
    assert_equal(
      {:index => 'hello $(foo) baz) world'},
      result[:tmpl],
      'Parser.parse_html[:tmpl] should be a proper template'
    )

    result = Bike::Parser.parse_html('hello $(foo = bar baz world')
    assert_equal(
      {'foo' => {:klass => 'bar', :tokens => ['baz', 'world']}},
      result[:item],
      'Parser.parse_html should be able to parse a tag that is not closed'
    )
    assert_equal(
      {:index => 'hello $(foo)'},
      result[:tmpl],
      'Parser.parse_html should be able to parse a tag that is not closed'
    )

    result = Bike::Parser.parse_html('hello $(foo = bar "baz"world)')
    assert_equal(
      {'foo' => {:klass => 'bar', :tokens => ['baz', 'world']}},
      result[:item],
      'Parser.parse_html should be able to parse tokens without a delimiter'
    )
    assert_equal(
      {:index => 'hello $(foo)'},
      result[:tmpl],
      'Parser.parse_html should be able to parse tokens without a delimiter'
    )

    result = Bike::Parser.parse_html('hello $(foo = bar, "baz")')
    assert_equal(
      {'foo' => {:klass => 'bar', :options => ['baz']}},
      result[:item],
      'The first token should be regarded as [:klass]'
    )
  end

  def test_parse_token
    assert_equal(
      {:width => 160, :height => 120},
      Bike::Parser.parse_token(nil, '160*120', {}),
      'Parser.parse_token should be able to parse dimension tokens'
    )
    assert_equal(
      {:min => 1, :max => 32},
      Bike::Parser.parse_token(nil, '1..32', {}),
      'Parser.parse_token should be able to parse range tokens'
    )
    assert_equal(
      {:max => 32},
      Bike::Parser.parse_token(nil, '..32', {}),
      'Parser.parse_token should be able to parse partial range tokens'
    )
    assert_equal(
      {:min => 1},
      Bike::Parser.parse_token(nil, '1..', {}),
      'Parser.parse_token should be able to parse partial range tokens'
    )
    assert_equal(
      {:min => -32, :max => -1},
      Bike::Parser.parse_token(nil, '-32..-1', {}),
      'Parser.parse_token should be able to parse minus range tokens'
    )

    assert_equal(
      {:options => ['foo']},
      Bike::Parser.parse_token(',', 'foo', {}),
      'Parser.parse_token should be able to parse option tokens'
    )
    assert_equal(
      {:options => ['foo', 'bar']},
      Bike::Parser.parse_token(',', 'bar', {:options => ['foo']}),
      'Parser.parse_token should be able to parse option tokens'
    )

    assert_equal(
      {:default => 'bar'},
      Bike::Parser.parse_token(':', 'bar', {}),
      'Parser.parse_token should be able to parse default tokens'
    )
    assert_equal(
      {:defaults => ['bar', 'baz']},
      Bike::Parser.parse_token(';', 'baz', {:defaults => ['bar']}),
      'Parser.parse_token should be able to parse defaults tokens'
    )
  end

  def test_parse_options
    result = Bike::Parser.parse_html('hello $(foo = bar , "baz baz", "world", hi qux)')
    assert_equal(
      {'foo' => {:klass => 'bar', :options => ['baz baz', 'world', 'hi'], :tokens => ['qux']}},
      result[:item],
      'Parser.parse_html should be able to parse a sequence of CSV'
    )
    result = Bike::Parser.parse_html('hello $(foo = bar "baz baz", "world", hi qux)')
    assert_equal(
      {'foo' => {:klass => 'bar', :options => ['baz baz', 'world', 'hi'], :tokens => ['qux']}},
      result[:item],
      'Parser.parse_html should be able to parse a sequence of CSV'
    )
  end

  def test_parse_options_with_spaces
    result = Bike::Parser.parse_html('hello $(foo = bar world, qux)')
    assert_equal(
      {'foo' => {:klass => 'bar', :options => ['world', 'qux']}},
      result[:item],
      'Parser.parse_html should allow spaces after the comma'
    )
    result = Bike::Parser.parse_html('hello $(foo = bar world , qux)')
    assert_equal(
      {'foo' => {:klass => 'bar', :options => ['qux'], :tokens => ['world']}},
      result[:item],
      'Parser.parse_html should not allow spaces before the comma'
    )
    result = Bike::Parser.parse_html('hello $(foo = bar "baz baz", "world", hi qux)')
    assert_equal(
      {'foo' => {:klass => 'bar', :options => ['baz baz', 'world', 'hi'], :tokens => ['qux']}},
      result[:item],
      'Parser.parse_html should allow spaces after the comma'
    )

    result = Bike::Parser.parse_html(<<'_eos')
hello $(foo =
  bar
  "baz baz",
  "world",
  hi
  qux)
_eos
    assert_equal(
      {'foo' => {:klass => 'bar', :options => ['baz baz', 'world', 'hi'], :tokens => ['qux']}},
      result[:item],
      'Parser.parse_html should allow spaces after the comma'
    )
  end

  def test_parse_defaults
    result = Bike::Parser.parse_html('hello $(foo = bar ;"baz baz";"world";hi qux)')
    assert_equal(
      {'foo' => {:klass => 'bar', :defaults => ['baz baz', 'world', 'hi'], :tokens => ['qux']}},
      result[:item],
      'Parser.parse_html should be able to parse a sequence of CSV as [:defaults]'
    )
    result = Bike::Parser.parse_html('hello $(foo = bar "baz baz";"world";hi qux)')
    assert_equal(
      {'foo' => {:klass => 'bar', :defaults => ['baz baz', 'world', 'hi'], :tokens => ['qux']}},
      result[:item],
      'Parser.parse_html should be able to parse a sequence of CSV as [:defaults]'
    )
  end

  def test_parse_defaults_with_spaces
    result = Bike::Parser.parse_html('hello $(foo=bar world; qux)')
    assert_equal(
      {'foo' => {:klass => 'bar', :defaults => ['world', 'qux']}},
      result[:item],
      'Parser.parse_html should allow spaces after the semicolon'
    )
    result = Bike::Parser.parse_html('hello $(foo=bar world ;qux)')
    assert_equal(
      {'foo' => {:klass => 'bar', :defaults => ['qux'], :tokens => ['world']}},
      result[:item],
      'Parser.parse_html should not allow spaces before the semicolon'
    )
    result = Bike::Parser.parse_html('hello $(foo=bar "baz baz"; "world"; hi qux)')
    assert_equal(
      {'foo' => {:klass => 'bar', :defaults => ['baz baz', 'world', 'hi'], :tokens => ['qux']}},
      result[:item],
      'Parser.parse_html should allow spaces after the comma'
    )

    result = Bike::Parser.parse_html(<<'_eos')
hello $(foo =
  bar
  "baz baz";
  "world";
  hi
  qux)
_eos
    assert_equal(
      {'foo' => {:klass => 'bar', :defaults => ['baz baz', 'world', 'hi'], :tokens => ['qux']}},
      result[:item],
      'Parser.parse_html should allow spaces after the comma'
    )
  end

  def test_parse_meta_tag
    result = Bike::Parser.parse_html <<'_html'
<html>
  <meta name="bike-owner" content="frank" />
</html>
_html
    assert_equal(
      {
        :tmpl  => {
          :index => <<'_html',
<html>
</html>
_html
        },
        :item  => {},
        :owner => 'frank',
        :label => nil,
      },
      result,
      'Parser.parse_html should scrape meta vals from <meta>'
    )

    result = Bike::Parser.parse_html <<'_html'
<html>
  <meta name="bike-owner" content="frank" />
  <meta name="bike-group" content="bob,carl" />
  <meta name="bike-foo" content="bar, baz" />
  <meta name="bike-label" content="Qux" />
</html>
_html
    assert_equal(
      {
        :tmpl  => {
          :index => <<'_html',
<html>
</html>
_html
        },
        :item  => {},
        :owner => 'frank',
        :group => %w(bob carl),
        :foo   => %w(bar baz),
        :label => 'Qux',
      },
      result,
      'Parser.parse_html should scrape meta vals from <meta>'
    )
  end

  def test_parse_duplicate_tag
    result = Bike::Parser.parse_html('hello $(foo = bar "baz baz") world $(foo=boo) $(foo)!')
    assert_equal(
      {'foo' => {:klass => 'boo'}},
      result[:item],
      'definition tags are overridden by a preceding definition'
    )
    assert_equal(
      {:index => 'hello $(foo) world $(foo) $(foo)!'},
      result[:tmpl],
      'Parser.parse_html[:tmpl] should be a proper template'
    )
  end

  def test_scan_inner_html
    s = StringScanner.new 'bar</foo>bar'
    inner_html, close_tag = Bike::Parser.scan_inner_html(s, 'foo')
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
    inner_html, close_tag = Bike::Parser.scan_inner_html(s, 'foo')
    assert_equal(
      '<foo>bar</foo>',
      inner_html,
      'Parser.scan_inner_html should be aware of nested tags'
    )

    s = StringScanner.new "baz\n  <foo>bar</foo>\n</foo>"
    inner_html, close_tag = Bike::Parser.scan_inner_html(s, 'foo')
    assert_equal(
      "baz\n  <foo>bar</foo>\n",
      inner_html,
      'Parser.scan_inner_html should be aware of nested tags'
    )
  end

  def test_scan_comment
    s = StringScanner.new 'baz -->'
    inner_html, close_tag = Bike::Parser.scan_inner_html(s, '!--')
    assert_equal(
      'baz',
      inner_html,
      'Parser.scan_inner_html should parse html comments'
    )
    assert_equal(
      ' -->',
      close_tag,
      'Parser.scan_inner_html should parse html comments'
    )

    s = StringScanner.new "baz\n  <!--bar-->\n-->"
    inner_html, close_tag = Bike::Parser.scan_inner_html(s, '!--')
    assert_equal(
      "baz\n  <!--bar-->\n",
      inner_html,
      'Parser.scan_inner_html should parse nested comments'
    )
  end

  def test_scan_cdata
    s = StringScanner.new 'baz ]]>'
    inner_html, close_tag = Bike::Parser.scan_inner_html(s, '<![CDATA[')
    assert_equal(
      'baz',
      inner_html,
      'Parser.scan_inner_html should parse CDATA section'
    )
    assert_equal(
      ' ]]>',
      close_tag,
      'Parser.scan_inner_html should parse CDATA section'
    )
  end

  def test_parse_block_tag
    result = Bike::Parser.parse_html <<'_html'
<ul class="app-blog" id="foo"><li>hello</li></ul>
_html
    assert_equal(
      {
        'foo' => {
          :klass    => 'set-dynamic',
          :workflow => 'blog',
          :tmpl     => {
            :index => <<'_tmpl'.chomp,
<ul class="app-blog" id="@(name)">$()</ul>
$(.navi)$(.submit)$(.action_create)
_tmpl
          },
          :item     => {
            'default' => {
              :label => nil,
              :tmpl  => {:index => '<li>hello</li>'},
              :item  => {},
            },
          },
        },
      },
      result[:item],
      'Parser.parse_html should be able to parse block bike tags'
    )
    assert_equal(
      {:index => '$(foo.message)$(foo)'},
      result[:tmpl],
      'Parser.parse_html[:tmpl] should be a proper template'
    )

    result = Bike::Parser.parse_html <<'_html'
<ul class="app-blog" id="foo">
  <li>hello</li>
</ul>
_html
    assert_equal(
      {
        'foo' => {
          :klass    => 'set-dynamic',
          :workflow => 'blog',
          :tmpl     => {
            :index => <<'_tmpl'.chomp,
<ul class="app-blog" id="@(name)">
$()</ul>
$(.navi)$(.submit)$(.action_create)
_tmpl
          },
          :item     => {
            'default' => {
              :label => nil,
              :tmpl  => {:index => "  <li>hello</li>\n"},
              :item  => {},
            },
          }
        },
      },
      result[:item],
      'Parser.parse_html should be able to parse block bike tags'
    )
    assert_equal(
      {:index => '$(foo.message)$(foo)'},
      result[:tmpl],
      'Parser.parse_html[:tmpl] should be a proper template'
    )

    result = Bike::Parser.parse_html <<'_html'
hello <ul class="app-blog" id="foo"><li>hello</li></ul> world
_html
    assert_equal(
      {
        'foo' => {
          :klass    => 'set-dynamic',
          :workflow => 'blog',
          :tmpl     => {
            :index => <<'_tmpl'.chomp,
 <ul class="app-blog" id="@(name)">$()</ul>$(.navi)$(.submit)$(.action_create)
_tmpl
          },
          :item     => {
            'default' => {
              :label => nil,
              :tmpl  => {:index => '<li>hello</li>'},
              :item  => {},
            },
          },
        },
      },
      result[:item],
      'Parser.parse_html should be able to parse block bike tags'
    )
    assert_equal(
      {:index => <<'_html'},
hello$(foo.message)$(foo) world
_html
      result[:tmpl],
      'Parser.parse_html[:tmpl] should be a proper template'
    )

    result = Bike::Parser.parse_html <<'_html'
hello <!-- cruel --> <ul class="app-blog" id="foo"><li>hello</li></ul> world
_html
    assert_equal(
      {
        'foo' => {
          :klass    => 'set-dynamic',
          :workflow => 'blog',
          :tmpl     => {
            :index => <<'_tmpl'.chomp,
 <ul class="app-blog" id="@(name)">$()</ul>$(.navi)$(.submit)$(.action_create)
_tmpl
          },
          :item     => {
            'default' => {
              :label => nil,
              :tmpl  => {:index => '<li>hello</li>'},
              :item  => {},
            },
          },
        },
      },
      result[:item],
      'Parser.parse_html should be able to parse block bike tags'
    )
    assert_equal(
      {:index => <<'_html'},
hello <!-- cruel -->$(foo.message)$(foo) world
_html
      result[:tmpl],
      'Parser.parse_html[:tmpl] should be a proper template'
    )
  end

  def test_parse_block_tag_in_comment
    [
      <<'_html',
hello <!--<ul class="app-blog" id="test1"><li>hello</li></ul>--> world
_html
      <<'_html',
<!--
<ul class="app-blog" id="test2">
  <li>hello</li>
</ul>
-->
_html
      <<'_html',
foo <!--
<ul class="app-blog" id="test3">
  <li>hello</li>
</ul>
--> bar
_html
      <<'_html',
foo <!--
<ul class="app-blog" id="test4">
  <li>hello</li>
</ul>
--> bar
_html
      <<'_html',
foo <!--
<ul class="app-blog" id="test5">
  <!-- may_preview -->
  <li>hello</li>
</ul>
--> bar
_html
      <<'_html',
<![CDATA[
  <ul class="app-blog" id="test6">
    <!-- may_preview -->
    <li>hello</li>
  </ul>
]]>
_html
      <<'_html',
<!--
<ul class="app-blog" id="test7">
  <!-- may_preview -->
  <li>hello</li>
</ul>
_html
    ].each {|html|
      result = Bike::Parser.parse_html html
      assert_equal(
        {},
        result[:item],
        'Parser.parse_html should skip bike tags in a comment'
      )
      assert_equal(
        {:index => html},
        result[:tmpl],
        'Parser.parse_html should skip bike tags in a comment'
      )
    }
  end

  def test_parse_block_tag_obsolete_runo_class
    result = Bike::Parser.parse_html <<'_html'
<ul class="runo-blog" id="foo"><li>hello</li></ul>
_html
    assert_equal(
      {
        'foo' => {
          :klass    => 'set-dynamic',
          :workflow => 'blog',
          :tmpl     => {
            :index => <<'_html'.chomp,
<ul class="runo-blog" id="@(name)">$()</ul>
$(.navi)$(.submit)$(.action_create)
_html
          },
          :item     => {
            'default' => {
              :label => nil,
              :tmpl  => {:index => '<li>hello</li>'},
              :item  => {},
            },
          },
        },
      },
      result[:item],
      'Parser.parse_html should be able to parse old runo tags'
    )
  end

  def test_parse_block_tag_obsolete_body_class
    result = Bike::Parser.parse_html <<'_html'
<ul class="app-blog" id="foo"><div>oops.</div><li class="body">hello</li></ul>
_html
    assert_equal(
      {
        'foo' => {
          :klass    => 'set-dynamic',
          :workflow => 'blog',
          :tmpl     => {
            :index => <<'_html'.chomp,
<ul class="app-blog" id="@(name)"><div>oops.</div>$()</ul>
$(.navi)$(.submit)$(.action_create)
_html
          },
          :item     => {
            'default' => {
              :label => nil,
              :tmpl  => {:index => '<li class="body">hello</li>'},
              :item  => {},
            },
          },
        },
      },
      result[:item],
      'Parser.parse_html should be able to parse block bike tags'
    )
  end

  def test_look_a_like_block_tag
    result = Bike::Parser.parse_html <<'_html'
hello <ul class="not-app-blog" id="foo"><li>hello</li></ul> world
_html
    assert_equal(
      {:index => <<'_tmpl'},
hello <ul class="not-app-blog" id="foo"><li>hello</li></ul> world
_tmpl
      result[:tmpl],
      "Parser.parse_html[:tmpl] should skip a class which does not start with 'bike'"
    )
  end

  def test_block_tags_with_options
    result = Bike::Parser.parse_html <<'_html'
hello
  <table class="app-blog" id="foo">
    <!-- 1..20 barbaz -->
    <tbody class="model"><!-- qux --><tr><th>$(bar=text)</th><th>$(baz=text)</th></tr></tbody>
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
          :tmpl     => {
            :index => <<'_tmpl'.chomp,
  <table class="app-blog" id="@(name)">
    <!-- 1..20 barbaz -->
$()  </table>
$(.navi)$(.submit)$(.action_create)
_tmpl
          },
          :item     => {
            'default' => {
              :label => nil,
              :tmpl  => {
                :index => <<'_tmpl',
    <tbody class="model"><!-- qux --><tr><th>$(.a_update)$(bar)</a></th><th>$(baz)$(.hidden)</th></tr></tbody>
_tmpl
              },
              :item  => {
                'bar' => {:klass => 'text'},
                'baz' => {:klass => 'text'},
              },
            },
          },
        },
      },
      result[:item],
      'Parser.parse_html should aware of <tbody class="model">'
    )
  end

  def test_block_tags_with_tbody
    result = Bike::Parser.parse_html <<'_html'
hello
  <table class="app-blog" id="foo">
    <thead><tr><th>BAR</th><th>BAZ</th></tr></thead>
    <tbody class="model"><tr><th>$(bar=text)</th><th>$(baz=text)</th></tr></tbody>
  </table>
world
_html
    assert_equal(
      {
        'foo' => {
          :klass    => 'set-dynamic',
          :workflow => 'blog',
          :tmpl     => {
            :index => <<'_tmpl'.chomp,
  <table class="app-blog" id="@(name)">
    <thead><tr><th>BAR</th><th>BAZ</th></tr></thead>
$()  </table>
$(.navi)$(.submit)$(.action_create)
_tmpl
          },
          :item     => {
            'default' => {
              :label => nil,
              :tmpl  => {
                :index => <<'_tmpl',
    <tbody class="model"><tr><th>$(.a_update)$(bar)</a></th><th>$(baz)$(.hidden)</th></tr></tbody>
_tmpl
              },
              :item  => {
                'bar' => {:klass => 'text'},
                'baz' => {:klass => 'text'},
              },
            },
          },
        },
      },
      result[:item],
      'Parser.parse_html should aware of <tbody class="model">'
    )
    assert_equal(
      {:index => <<'_tmpl'},
hello
$(foo.message)$(foo)world
_tmpl
      result[:tmpl],
      'Parser.parse_html[:tmpl] should be a proper template'
    )
  end

  def test_parse_xml
    result = Bike::Parser.parse_xml <<'_html'
<channel class="app-rss">
  <link>@(href)</link>
  <item class="model">
    <title>$(title)</title>
  </item>
</channel>
_html
    assert_equal(
      {
        :label => nil,
        :tmpl  => {:index => '$(main)'},
        :item  => {
          'main' => {
            :item => {
              'default' => {
                :label => nil,
                :item  => {},
                :tmpl  => {
                    :index => <<'_xml'
  <item>
    <title>$(title)</title>
  </item>
_xml
                },
              },
            },
            :tmpl => {
              :index => <<'_xml',
<channel>
  <link>@(href)</link>
$()</channel>
_xml
            },
            :klass => 'set-dynamic',
            :workflow => 'rss',
          }
        },
      },
      result,
      'Parser.parse_html should aware of <item>'
    )
  end

  def test_parse_item_label
    result = Bike::Parser.parse_html <<'_html'
<ul class="app-blog" id="foo"><li title="Greeting">hello</li></ul>
_html
    assert_equal(
      'Greeting',
      result[:item]['foo'][:item]['default'][:label],
      'Parser.parse_html should pick up item labels from title attrs'
    )

    result = Bike::Parser.parse_html <<'_html'
<ul class="app-blog" id="foo"><!-- foo --><li title="Greeting">hello</li></ul>
_html
    assert_equal(
      'Greeting',
      result[:item]['foo'][:item]['default'][:label],
      'Parser.parse_html should pick up item labels from title attrs'
    )

    result = Bike::Parser.parse_html <<'_html'
<ul class="app-blog" id="foo"><!-- foo --><li><div title="Foo">hello</div></li></ul>
_html
    assert_nil(
      result[:item]['foo'][:item]['default'][:label],
      'Parser.parse_html should pick up item labels only from the first tags'
    )
  end

  def test_parse_item_label_plural
    result = Bike::Parser.parse_html <<'_html'
<ul class="app-blog" id="foo"><li title="tEntry, tEntries">hello</li></ul>
_html
    assert_equal(
      'tEntry',
      result[:item]['foo'][:item]['default'][:label],
      'Parser.parse_html should split plural item labels'
    )
    assert_equal(
      ['tEntry', 'tEntries'],
      Bike::I18n.msg['tEntry'],
      'Parser.parse_html should I18n.merge_msg! the plural item labels'
    )

    result = Bike::Parser.parse_html <<'_html'
<ul class="app-blog" id="foo"><li title="tFooFoo, BarBar, BazBaz">hello</li></ul>
_html
    assert_equal(
      'tFooFoo',
      result[:item]['foo'][:item]['default'][:label],
      'Parser.parse_html should split plural item labels'
    )
    assert_equal(
      ['tFooFoo', 'BarBar', 'BazBaz'],
      Bike::I18n.msg['tFooFoo'],
      'Parser.parse_html should I18n.merge_msg! the plural item labels'
    )

    result = Bike::Parser.parse_html <<'_html'
<ul class="app-blog" id="foo"><li title="tQux">hello</li></ul>
_html
    assert_equal(
      'tQux',
      result[:item]['foo'][:item]['default'][:label],
      'Parser.parse_html should split plural item labels'
    )
    assert_equal(
      ['tQux', 'tQux', 'tQux', 'tQux'],
      Bike::I18n.msg['tQux'],
      'Parser.parse_html should repeat a singular label to fill all possible plural forms'
    )
  end

  def test_block_tags_with_nested_tbody
    result = Bike::Parser.parse_html <<'_html'
hello
  <table class="app-blog" id="foo">
    <thead><tr><th>BAR</th><th>BAZ</th></tr></thead>
    <tbody class="model"><tbody><tr><th>$(bar=text)</th><th>$(baz=text)</th></tr></tbody></tbody>
  </table>
world
_html
    assert_equal(
      {
        'foo' => {
          :klass    => 'set-dynamic',
          :workflow => 'blog',
          :tmpl     => {
            :index => <<'_tmpl'.chomp,
  <table class="app-blog" id="@(name)">
    <thead><tr><th>BAR</th><th>BAZ</th></tr></thead>
$()  </table>
$(.navi)$(.submit)$(.action_create)
_tmpl
          },
          :item     => {
            'default' => {
              :label => nil,
              :tmpl  => {
                :index => <<'_tmpl',
    <tbody class="model"><tbody><tr><th>$(.a_update)$(bar)</a></th><th>$(baz)$(.hidden)</th></tr></tbody></tbody>
_tmpl
              },
              :item  => {
                'bar' => {:klass => 'text'},
                'baz' => {:klass => 'text'},
              },
            },
          },
        },
      },
      result[:item],
      'Parser.parse_html should aware of nested <tbody class="model">'
    )
  end

  def test_nested_block_tags
    result = Bike::Parser.parse_html <<'_html'
<ul class="app-blog" id="foo">
  <li>
    <ul class="app-blog" id="bar"><li>baz</li></ul>
  </li>
</ul>
_html
    assert_equal(
      {
        'foo' => {
          :klass    => 'set-dynamic',
          :workflow => 'blog',
          :tmpl     => {
            :index => <<'_tmpl'.chomp,
<ul class="app-blog" id="@(name)">
$()</ul>
$(.navi)$(.submit)$(.action_create)
_tmpl
          },
          :item     => {
            'default' => {
              :label => nil,
              :tmpl  => {
                :index => <<'_tmpl',
  <li>
$(bar.message)$(.a_update)$(bar)$(.hidden)</a>  </li>
_tmpl
              },
              :item  => {
                'bar' => {
                  :klass    => 'set-dynamic',
                  :workflow => 'blog',
                  :tmpl     => {
                    :index => <<'_tmpl'.chomp,
    <ul class="app-blog" id="@(name)">$()</ul>
$(.navi)$(.submit)$(.action_create)
_tmpl
                  },
                  :item     => {
                    'default' => {
                      :label => nil,
                      :tmpl  => {:index => '<li>baz</li>'},
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
      'Parser.parse_html should be able to parse nested block bike tags'
    )
    assert_equal(
      {:index => '$(foo.message)$(foo)'},
      result[:tmpl],
      'Parser.parse_html[:tmpl] should be a proper template'
    )
  end

  def test_combination
    result = Bike::Parser.parse_html <<'_html'
<html>
  <h1>$(title=text 32)</h1>
  <ul id="foo" class="app-blog">
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
        'title' => {:klass => 'text', :tokens => ['32']},
        'foo'   => {
          :klass    => 'set-dynamic',
          :workflow => 'blog',
          :tmpl     => {
            :index => <<'_tmpl'.chomp,
  <ul id="@(name)" class="app-blog">
$()  </ul>
$(.navi)$(.submit)$(.action_create)
_tmpl
          },
          :item     => {
            'default' => {
              :label => nil,
              :tmpl  => {
                :index => <<'_tmpl',
    <li>
      $(.a_update)$(subject)</a>
      $(body)$(.hidden)
      <ul><li>qux</li></ul>
    </li>
_tmpl
              },
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
      'Parser.parse_html should be able to parse combination of mixed bike tags'
    )
    assert_equal(
      {:index => <<'_tmpl'},
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
    result = Bike::Parser.gsub_block('a<div class="foo">bar</div>c', 'foo') {|open, inner, close|
      match = [open, inner, close]
      'b'
    }
    assert_equal(
      'abc',
      result,
      'Parser.gsub_block should replace tag blocks of the matching class with the given value'
    )
    assert_equal(
      ['<div class="foo">', 'bar', '</div>'],
      match,
      'Parser.gsub_block should pass the matching element to its block'
    )

    result = Bike::Parser.gsub_block('<p><div class="foo">bar</div></p>', 'foo') {|open, inner, close|
      match = [open, inner, close]
      'b'
    }
    assert_equal(
      '<p>b</p>',
      result,
      'Parser.gsub_block should replace tag blocks of the matching class with the given value'
    )
    assert_equal(
      ['<div class="foo">', 'bar', '</div>'],
      match,
      'Parser.gsub_block should pass the matching element to its block'
    )

    result = Bike::Parser.gsub_block('a<p><div class="foo">bar</div></p>c', 'foo') {|open, inner, close|
      match = [open, inner, close]
      'b'
    }
    assert_equal(
      'a<p>b</p>c',
      result,
      'Parser.gsub_block should replace tag blocks of the matching class with the given value'
    )
    assert_equal(
      ['<div class="foo">', 'bar', '</div>'],
      match,
      'Parser.gsub_block should pass the matching element to its block'
    )
  end

  def _test_gsub_action_tmpl(html)
    result = {}
    html = Bike::Parser.gsub_action_tmpl(html) {|id, action, *tmpl|
      result[:id]     = id
      result[:action] = action
      result[:tmpl]   = tmpl.join
      'b'
    }
    [result, html]
  end

  def test_gsub_action_tmpl
    result, html = _test_gsub_action_tmpl 'a<div class="foo-navi">Foo</div>c'
    assert_equal(
      {
        :id     => 'foo',
        :action => :navi,
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

    result, html = _test_gsub_action_tmpl 'a<div class="bar foo-navi">Foo</div>c'
    assert_equal(
      {
        :id     => 'foo',
        :action => :navi,
        :tmpl   => '<div class="bar foo-navi">Foo</div>',
      },
      result,
      'Parser.gsub_action_tmpl should yield action templates'
    )

    result, html = _test_gsub_action_tmpl 'a<div class="bar foo-navi baz">Foo</div>c'
    assert_equal(
      {
        :id     => 'foo',
        :action => :navi,
        :tmpl   => '<div class="bar foo-navi baz">Foo</div>',
      },
      result,
      'Parser.gsub_action_tmpl should yield action templates'
    )

    result, html = _test_gsub_action_tmpl 'a<div class="bar foo-done baz">Foo</div>c'
    assert_equal(
      {
        :id     => 'foo',
        :action => :done,
        :tmpl   => '<div class="bar foo-done baz">Foo</div>',
      },
      result,
      'Parser.gsub_action_tmpl should yield action templates'
    )
  end

  def test_gsub_action_tmpl_with_empty_id
    result, html = _test_gsub_action_tmpl 'a<div class="navi">Foo</div>c'
    assert_equal(
      {
        :id     => nil,
        :action => :navi,
        :tmpl   => '<div class="navi">Foo</div>',
      },
      result,
      'Parser.gsub_action_tmpl should yield action templates'
    )

    result, html = _test_gsub_action_tmpl 'a<div class="foo navi">Foo</div>c'
    assert_equal(
      {
        :id     => nil,
        :action => :navi,
        :tmpl   => '<div class="foo navi">Foo</div>',
      },
      result,
      'Parser.gsub_action_tmpl should yield action templates'
    )

    result, html = _test_gsub_action_tmpl 'a<div class="foo navi baz">Foo</div>c'
    assert_equal(
      {
        :id     => nil,
        :action => :navi,
        :tmpl   => '<div class="foo navi baz">Foo</div>',
      },
      result,
      'Parser.gsub_action_tmpl should yield action templates'
    )
  end

  def test_gsub_action_tmpl_with_ambiguous_klass
    result, html = _test_gsub_action_tmpl 'a<div class="not_navi">Foo</div>c'
    assert_equal(
      {},
      result,
      'Parser.gsub_action_tmpl should ignore classes other than action, view, navi or submit'
    )

    result, html = _test_gsub_action_tmpl 'a<div class="navi_bar">Foo</div>c'
    assert_equal(
      {
        :id     => nil,
        :action => :navi_bar,
        :tmpl   => '<div class="navi_bar">Foo</div>',
      },
      result,
      'Parser.gsub_action_tmpl should yield an action template if the klass looks like special'
    )
  end

  def test_action_tmpl_in_ss
    result = Bike::Parser.parse_html <<'_html'
<html>
  <ul id="foo" class="app-blog">
    <li>$(subject=text)</li>
  </ul>
  <div class="foo-navi">bar</div>
</html>
_html
    assert_equal(
      <<'_tmpl',
  <div class="foo-navi">bar</div>
_tmpl
      result[:item]['foo'][:tmpl][:navi],
      'Parser.parse_html should parse action templates in the html'
    )
    assert_equal(
      {:index => <<'_tmpl'},
<html>
$(foo.message)$(foo)$(foo.navi)</html>
_tmpl
      result[:tmpl],
      'Parser.parse_html should replace action templates with proper tags'
    )
  end

  def test_action_tmpl_in_ss_with_nil_id
    result = Bike::Parser.parse_html <<'_html'
<html>
  <ul id="main" class="app-blog">
    <li>$(subject=text)</li>
  </ul>
  <div class="navi">bar</div>
</html>
_html
    assert_equal(
      <<'_tmpl',
  <div class="navi">bar</div>
_tmpl
      result[:item]['main'][:tmpl][:navi],
      "Parser.parse_html should set action templates to item['main'] by default"
    )
    assert_equal(
      {:index => <<'_tmpl'},
<html>
$(main.message)$(main)$(main.navi)</html>
_tmpl
      result[:tmpl],
      "Parser.parse_html should set action templates to item['main'] by default"
    )
  end

  def test_action_tmpl_in_ss_with_non_existent_id
    result = Bike::Parser.parse_html <<'_html'
<html>
  <ul id="main" class="app-blog">
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
      {:index => <<'_tmpl'},
<html>
$(main.message)$(main)  <div class="non_existent-navi">bar</div>
</html>
_tmpl
      result[:tmpl],
      'Parser.parse_html should ignore the action template without a corresponding SD'
    )
  end

  def test_action_tmpl_in_ss_with_nested_action_tmpl
    result = Bike::Parser.parse_html <<'_html'
<html>
  <ul id="foo" class="app-blog">
    <li>$(subject=text)</li>
  </ul>
  <div class="foo-navi"><span class="navi_prev">prev</span></div>
</html>
_html
    assert_equal(
      <<'_html',
  <div class="foo-navi">$(.navi_prev)</div>
_html
      result[:item]['foo'][:tmpl][:navi],
      'Parser.parse_html should parse nested action templates'
    )
    assert_equal(
      '<span class="navi_prev">prev</span>',
      result[:item]['foo'][:tmpl][:navi_prev],
      'Parser.parse_html should parse nested action templates'
    )
    assert_equal(
      {
        :index     => <<'_html'.chomp,
  <ul id="@(name)" class="app-blog">
$()  </ul>
$(.submit)$(.action_create)
_html
        :navi      => <<'_html',
  <div class="foo-navi">$(.navi_prev)</div>
_html
        :navi_prev => '<span class="navi_prev">prev</span>',
      },
      result[:item]['foo'][:tmpl],
      'Parser.parse_html should parse nested action templates'
    )

    result = Bike::Parser.parse_html <<'_html'
<html>
  <ul id="foo" class="app-blog">
    <li>$(subject=text)</li>
  </ul>
  <div class="foo-navi"><span class="bar-navi_prev">prev</span></div>
</html>
_html
    assert_equal(
      '<span class="bar-navi_prev">prev</span>',
      result[:item]['foo'][:tmpl][:navi_prev],
      'Parser.parse_html should ignore the id of a nested action template'
    )
  end

  def test_action_tmpl_in_sd
    result = Bike::Parser.parse_html <<'_html'
<ul id="foo" class="app-blog">
  <li class="model">$(text)</li>
  <div class="navi">bar</div>
</ul>
_html
    assert_equal(
      <<'_html',
  <div class="navi">bar</div>
_html
      result[:item]['foo'][:tmpl][:navi],
      'Parser.parse_html should parse action templates in sd[:tmpl]'
    )
    assert_match(
      %r{\$\(\.navi\)},
      result[:item]['foo'][:tmpl][:index],
      'Parser.parse_html should parse action templates in sd[:tmpl]'
    )
  end

  def test_action_tmpl_in_sd_with_nested_action_tmpl
    result = Bike::Parser.parse_html <<'_html'
<ul id="foo" class="app-blog">
  <li class="model">$(text)</li>
  <div class="navi"><span class="navi_prev">prev</span></div>
</ul>
_html
    assert_equal(
      <<'_html',
  <div class="navi">$(.navi_prev)</div>
_html
      result[:item]['foo'][:tmpl][:navi],
      'Parser.parse_html should parse nested action templates in sd[:tmpl]'
    )
    assert_equal(
      '<span class="navi_prev">prev</span>',
      result[:item]['foo'][:tmpl][:navi_prev],
      'Parser.parse_html should parse nested action templates in sd[:tmpl]'
    )
  end

  def test_action_tmpl_in_comment
    result = Bike::Parser.parse_html <<'_html'
<ul id="foo" class="app-blog">
  <li class="model">$(text)</li>
  <!--
  <div class="navi"><span class="navi_prev">prev</span></div>
  -->
</ul>
_html
    assert_nil(
      result[:item]['foo'][:tmpl][:navi],
      'Parser.parse_html should skip action templates in a comment'
    )

    result = Bike::Parser.parse_html <<'_html'
<ul id="foo" class="app-blog">
  <li class="model">$(text)</li>
  <div class="navi"><!--<span class="navi_prev">prev</span>--></div>
</ul>
_html
    assert_equal(
      <<'_html',
  <div class="navi"><!--<span class="navi_prev">prev</span>--></div>
_html
      result[:item]['foo'][:tmpl][:navi],
      'Parser.parse_html should skip action templates in a comment'
    )
  end

  def test_supplement_sd
    result = Bike::Parser.parse_html <<'_html'
<ul id="foo" class="app-blog">
  <li class="model">$(text)</li>
</ul>
_html
    assert_match(
      /\$\(\.navi\)/,
      result[:item]['foo'][:tmpl][:index],
      'Parser.supplement_sd should supplement sd[:tmpl] with default menus'
    )

    result = Bike::Parser.parse_html <<'_html'
<ul id="foo" class="app-blog">
  <div class="navi">bar</div>
  <li class="model">$(text)</li>
</ul>
_html
    assert_no_match(
      /\$\(\.navi\).*\$\(\.navi\)/m,
      result[:item]['foo'][:tmpl][:index],
      'Parser.supplement_sd should not supplement sd[:tmpl] when it already has the menu'
    )

    result = Bike::Parser.parse_html <<'_html'
<div class="foo-navi">bar</div>
<ul id="foo" class="app-blog">
  <li class="model">$(text)</li>
</ul>
_html
    assert_no_match(
      /\$\(\.navi\)/,
      result[:item]['foo'][:tmpl][:index],
      'Parser.supplement_sd should not supplement sd[:tmpl] when it already has the menu'
    )
  end

  def test_supplement_ss
    result = Bike::Parser.parse_html <<'_html'
<ul id="foo" class="app-blog">
  <li class="model">$(text)</li>
</ul>
_html
    assert_match(
      /\$\(\.a_update\)/,
      result[:item]['foo'][:item]['default'][:tmpl][:index],
      'Parser.supplement_ss should supplement ss[:tmpl] with default menus'
    )

    result = Bike::Parser.parse_html <<'_html'
<ul id="foo" class="app-blog">
  <li class="model">$(text) $(.action_update)</li>
</ul>
_html
    assert_no_match(
      /\$\(\.a_update\)/,
      result[:item]['foo'][:item]['default'][:tmpl][:index],
      'Parser.supplement_ss should not supplement ss[:tmpl] when it already has the menu'
    )
  end

end
