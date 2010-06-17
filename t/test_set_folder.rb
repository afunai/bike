# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class TC_Set_Folder < Test::Unit::TestCase

  def setup
    Runo.client = 'root'
    Runo.current[:base] = nil
    Runo.current[:uri]  = nil
  end

  def teardown
  end

  def test_root
    root = Runo::Set::Static::Folder.root
    assert_instance_of(
      Runo::Set::Static::Folder,
      root,
      'Folder.root should return the root folder instance'
    )
  end

  def test_initialize
    folder = Runo::Set::Static::Folder.new(:id => 'foo', :parent => nil)
    assert_match(
      /^<html>/,
      folder[:html],
      'Folder#initialize should load [:html] from [:dir]/index.html'
    )
    assert_instance_of(
      Runo::Set::Dynamic,
      folder.item('main'),
      'Folder#initialize should load the items according to [:html]'
    )
  end

  def test_meta_html_dir
    folder = Runo::Set::Static::Folder.root.item('foo')
    assert_equal(
      '/foo',
      folder[:html_dir],
      "Folder#meta_html_dir should return meta_dir if there is 'index.html'"
    )

    folder = Runo::Set::Static::Folder.root.item('foo', 'bar')
    assert_equal(
      '/foo',
      folder[:html_dir],
      "Folder#meta_html_dir should return parent[:html_dir] if there is no 'index.html' in [:dir]"
    )
  end

  def test_meta_base_href
    folder = Runo::Set::Static::Folder.root.item('t_summary')

    Runo.current[:uri] = 'http://example.com'
    assert_equal(
      'http://example.com/t_summary/',
      folder[:base_href],
      'Folder#meta_base_href should return a full URI when Runo.uri is available'
    )

    Runo.current[:uri] = nil
    assert_equal(
      '/t_summary/',
      folder[:base_href],
      'Folder#meta_base_href should return [:dir] when Runo.uri is not available'
    )
  end

  def test_default_items
    folder = Runo::Set::Static::Folder.new(:id => 'foo', :parent => nil)
    assert_instance_of(
      Runo::Text,
      folder.item('_label'),
      'Folder#initialize should always load the default items'
    )
    assert_equal(
      'Foo Folder',
      folder.val('_label'),
      'Folder#initialize should load the val from [:dir].yaml'
    )
    assert_equal(
      'frank',
      folder.val('_owner'),
      'Folder#initialize should load the val from [:dir].yaml'
    )
  end

  def test_child_folder
    folder = Runo::Set::Static::Folder.new(:id => 'foo', :parent => nil)
    child  = folder.item('bar')
    assert_instance_of(
      Runo::Set::Static::Folder,
      child,
      'Folder#item should look the real directory for the child item'
    )
    assert_equal(
      'Bar Folder',
      child.val('_label'),
      'Folder#initialize should load the val from [:dir].yaml'
    )
    assert_equal(
      'frank',
      child.val('_owner'),
      'Folder#initialize should inherit the val of default items from [:parent]'
    )
  end

  def test_item
    folder = Runo::Set::Static::Folder.root.item('foo')
    assert_instance_of(
      Runo::Set::Static,
      folder.item('main', '20091120_0001'),
      'Folder#item should work just like any other sets'
    )
    assert_instance_of(
      Runo::Set::Static,
      folder.item('20091120_0001'),
      "Folder#item should delegate to item('main') if full-formatted :id is given"
    )
  end

  def test_merge_tmpl
    folder = Runo::Set::Static::Folder.root

    index = {
      :item => {
        'main' => {
          :item => {
            'default' => {
              :tmpl => {:index => '<li><ul>$(files)</ul></li>'},
              :item => {
                'files' => {
                  :tmpl => {:index => '<ol>$()</ol>'},
                  :item => {
                    'default' => {
                      :tmpl => {:index => '<li>$(file)</li>'},
                      :item => {'file' => {:klass => 'text'}},
                    },
                  },
                },
              },
            },
          },
          :tmpl => {:index => '<ul>$()</ul>'},
        },
      },
      :tmpl => {:index => '<html>$(main)</html>'},
    }
    summary = {
      :item => {
        'main' => {
          :foo  => 'this should not be merged.',
          :item => {
            'default' => {
              :bar  => 'this should not be merged.',
              :tmpl => {:summary => '<li class ="s"><ul>$(files)</ul></li>'},
              :item => {
                'files' => {
                  :baz  => 'this should not be merged.',
                  :tmpl => {:summary => '<ol class ="s">$()</ol>'},
                  :item => {
                    'default' => {
                      :qux  => 'this should not be merged.',
                      :tmpl => {:summary => '<li class ="s">$(file)</li>'},
                    },
                  },
                },
              },
            },
          },
          :tmpl => {:summary => '<ul class ="s">$()</ul>'},
        },
      },
      :tmpl => {:summary => '<html class ="s">$(main)</html>'},
    }

    assert_equal(
      {
        :item => {
          'main' => {
            :item => {
              'default' => {
                :tmpl => {
                  :index   => '<li><ul>$(files)</ul></li>',
                  :summary => '<li class ="s"><ul>$(files)</ul></li>',
                },
                :item => {
                  'files' => {
                    :tmpl => {
                      :index   => '<ol>$()</ol>',
                      :summary => '<ol class ="s">$()</ol>',
                    },
                    :item => {
                      'default' => {
                        :tmpl => {
                          :index   => '<li>$(file)</li>',
                          :summary => '<li class ="s">$(file)</li>',
                        },
                        :item => {'file' => {:klass => 'text'}},
                      },
                    },
                  },
                },
              },
            },
            :tmpl => {
              :index   => '<ul>$()</ul>',
              :summary => '<ul class ="s">$()</ul>',
            },
          },
        },
        :tmpl => {
          :index   => '<html>$(main)</html>',
          :summary => '<html class ="s">$(main)</html>',
        },
      },
      folder.send(:merge_tmpl, index, summary),
      'Folder#merge_tmpl should merge parsed metas'
    )
  end

  def test_tmpl_summary
    folder = Runo::Set::Static::Folder.root.item('t_summary')
    assert_equal(
      <<'_html',
<html>
<head><base href="@(base_href)" /><title>index</title></head>
<body>
<h1>index</h1>
$(main.message)$(main)</body>
</html>
_html
      folder[:tmpl][:index],
      'Folder#initialize should load [:tmpl][:index] from [:dir]/index.html'
    )
    assert_equal(
      <<'_html',
<html>
<head><base href="@(base_href)" /><title>summary</title></head>
<body>
<h1>summary</h1>
$(main.message)$(main)</body>
</html>
_html
      folder[:tmpl][:summary],
      'Folder#initialize should load [:tmpl][:summary] from [:dir]/summary.html'
    )

    assert_equal(
      <<'_html'.chomp,
<ul id="@(name)" class="runo-blog">
$()</ul>
$(.navi)$(.submit)$(.action_create)
_html
      folder[:item]['main'][:tmpl][:index],
      'Folder#initialize should load [:tmpl] of the child items'
    )
    assert_equal(
      <<'_html'.chomp,
<table id="@(name)" class="runo-blog">
$()</table>
$(.navi)$(.submit)$(.action_create)
_html
      folder[:item]['main'][:tmpl][:summary],
      'Folder#initialize should load [:tmpl][:summary] of the child items'
    )

    assert_equal(
      <<'_html',
  <li>$(.a_update)$(name)</a>: $(comment)$(.hidden)</li>
_html
      folder[:item]['main'][:item]['default'][:tmpl][:index],
      'Folder#initialize should load [:tmpl] of all the decendant items'
    )
    assert_equal(
      <<'_html',
  <tr><td><a href="$(.uri_detail)">$(name)</a></td><td>$(comment)</td></tr>
_html
      folder[:item]['main'][:item]['default'][:tmpl][:summary],
      'Folder#initialize should load [:tmpl][:summary] of all the decendant items'
    )
  end

  def test_base_href
    folder = Runo::Set::Static::Folder.root.item('t_summary')

    assert_match(
      '<base href="@(base_href)" />',
      folder[:tmpl][:index],
      'Folder#initialize should supplement <base href=...> to [:tmpl][*]'
    )
    assert_match(
      '<base href="@(base_href)" />',
      folder[:tmpl][:summary],
      'Folder#initialize should supplement <base href=...> to [:tmpl][*]'
    )
  end

  def test_get_summary
    folder = Runo::Set::Static::Folder.root.item('t_summary')

    assert_equal(
      <<'_html',
<html>
<head><base href="/t_summary/" /><title>summary</title></head>
<body>
<h1>summary</h1>
<table id="main" class="runo-blog">
  <tr><td><a href="/t_summary/20100326/1/read_detail.html">frank</a></td><td>hi.</td></tr>
</table>
<div class="action_create"><a href="/t_summary/create.html">create new entry...</a></div>
</body>
</html>
_html
      folder.get(
        'main' => {:conds => {:p => 1}}
      ),
      'Set#get should use [:tmpl][:summary] when available and appropriate'
    )
    assert_equal(
      <<'_html',
<html>
<head><base href="/t_summary/" /><title>index</title></head>
<body>
<h1>index</h1>
<ul id="main" class="runo-blog">
  <li><a href="/t_summary/20100326/1/update.html">frank</a>: hi.</li>
</ul>
<div class="action_create"><a href="/t_summary/create.html">create new entry...</a></div>
</body>
</html>
_html
      folder.get(
        :action => :read,
        :sub_action => :detail,
        'main' => {:action => :read, :sub_action => :detail, :conds => {:p => 1}}
      ),
      'Set#get should not use [:tmpl][:summary] for :read -> :detail'
    )

    Runo.client = 'root'
    Runo.current[:base] = folder.item('main')
    folder.item('main')[:tid] = '12345.012'
    assert_equal(
      <<_html,
<html>
<head><base href="/t_summary/" /><title>index</title></head>
<body>
<h1>index</h1>
<form id="form_main" method="post" enctype="multipart/form-data" action="/t_summary/12345.012/update.html">
<input name="_token" type="hidden" value="#{Runo.token}" />
<ul id="main" class="runo-blog">
  <li><a><span class="text"><input type="text" name="20100326_0001-name" value="frank" size="32" /></span></a>: <span class="text"><input type="text" name="20100326_0001-comment" value="hi." size="64" /></span></li>
</ul>
<div class="submit">
  <input name=".status-public" type="submit" value="update" />
  <input name=".action-preview_delete" type="submit" value="delete..." />
</div>
</form>
</body>
</html>
_html
      folder.get(
        :action => :read,
        :sub_action => :detail,
        'main' => {:action => :update, :sub_action => nil, :conds => {:p => 1}}
      ),
      'Set#get should not use [:tmpl][:summary] for :update'
    )
  end

  def test_tmpl_create
    folder = Runo::Set::Static::Folder.root.item('t_summary')

    assert_equal(
      <<'_html',
<html>
<head><base href="/t_summary/" /><title>create</title></head>
<body>
<h1>create</h1>
<ul id="main" class="runo-blog">
  <li>main-create</li>
</ul>
<div class="submit">
  <input name="main.status-public" type="submit" value="create" />
</div>
</body>
</html>
_html
      folder.get(
        'main' => {:action => :create}
      ),
      'Set#get should use [:tmpl][:create] when available and appropriate'
    )
  end

  def test_tmpl_done
    folder = Runo::Set::Static::Folder.root.item('t_contact')
    assert_equal(
      <<'_html',
<html>
  <head><base href="@(base_href)" /><title>$(_label)</title></head>
  <body>
    <p>thank you!</p>
  </body>
</html>
_html
      folder[:tmpl][:done],
      'Folder#initialize should load [:tmpl][:done] from [:dir]/done.html'
    )
  end

  def test_g_login
    folder = Runo::Set::Static::Folder.root.item('t_contact')

    Runo.client = nil
    assert_equal(
      <<'_html',
<div class="action_login"><a href="/t_contact/login.html">login</a></div>
_html
      folder.get(:action => :action_login),
      'Folder#_g_login should return a link to login/logout according to the current client'
    )

    Runo.client = 'frank'
    assert_equal(
      <<_html,
<div class="action_logout"><a href="/t_contact/logout.html?_token=#{Runo.token}">logout</a></div>
_html
      folder.get(:action => :action_login),
      'Folder#_g_login should return a link to login/logout according to the current client'
    )
  end

  def test_g_signin
    folder = Runo::Set::Static::Folder.root.item('t_contact')

    Runo.client = nil
    assert_equal(
      <<'_html',
<div class="action_signin"><a href="/_users/create.html">sign in</a></div>
_html
      folder.get(:action => :action_signin),
      'Folder#_g_signin should return a link to sign-in if the current client is nobody'
    )

    Runo.client = 'frank'
    assert_nil(
      folder.get(:action => :action_signin),
      'Folder#_g_signin should return nil unless the current client is nobody'
    )
  end

  def test_g_me
    folder = Runo::Set::Static::Folder.root.item('t_contact')

    Runo.client = nil
    assert_equal(
      <<'_html',
<div class="me">
  <div class="action_login"><a href="/t_contact/login.html">login</a></div>
</div>
_html
      folder.get(:action => :me),
      'Folder#_g_me should return a link to login if the current client is nobody'
    )

    Runo.client = 'test'
    assert_equal(
      <<_html,
<div class="me">
  <a href="/_users/id=test/update.html">
    <span class="dummy_img" style="width: 72px; height: 72px;"></span>
  </a>
  <div class="client">test</div>
  <div class="roles">(user)</div>
  <div class="action_logout"><a href="/t_contact/logout.html?_token=#{Runo.token}">logout</a></div>
</div>
_html
      folder.get(:action => :me),
      'Folder#_g_me should return a thumbnail of the current client and a link to logout'
    )
  end

end
