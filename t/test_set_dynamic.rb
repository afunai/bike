# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class TC_Set_Dynamic < Test::Unit::TestCase

  def setup
    @sd = Bike::Set::Dynamic.new(
      :id       => 'foo',
      :klass    => 'set-dynamic',
      :workflow => 'blog',
      :group    => ['roy', 'don'],
      :tmpl     => {
        :index => <<'_tmpl'.chomp,
<ul id="foo" class="app-blog">
$()</ul>
$(.submit)
_tmpl
      },
      :item     => {
        'default' => Bike::Parser.parse_html(<<'_html')
  <li>$(name = text 16 0..16 :'nobody'): $(comment = text 64 :'hi.')$(.hidden)</li>
_html
      }
    )
    @sd[:conds] = {}
    @sd[:order] = nil
    @sd[:tmpl][:action_create] = ''
    def @sd._g_submit(arg)
      "[#{my[:id]}-#{arg[:orig_action]}#{arg[:sub_action] && ('.' + arg[:sub_action].to_s)}]\n"
    end
    @sd[:item]['default'][:item].delete '_timestamp'
    Bike.client = 'root'
    Bike.current[:base] = nil
  end

  def teardown
    Bike.client = nil
  end

  def test_storage
    assert_kind_of(
      Bike::Storage,
      @sd.storage,
      'Set::Dynamic#instance should load an apropriate storage for the list'
    )
    assert_instance_of(
      Bike::Storage::Temp,
      @sd.storage,
      'Set::Dynamic#instance should load an apropriate storage for the list'
    )
  end

  class Bike::Workflow::Default_meta < Bike::Workflow
    DEFAULT_META = {:foo => 'FOO'}
  end
  def test_default_meta
    sd = Bike::Set::Dynamic.new(:workflow  => 'default_meta')
    assert_equal(
      'FOO',
      sd[:foo],
      'Set::Dynamic#[] should look for the default value in the workflow'
    )

    sd = Bike::Set::Dynamic.new(:workflow  => 'default_meta', :foo => 'BAR')
    assert_equal(
      'BAR',
      sd[:foo],
      'workflow.DEFAULT_META should be eclipsed by @meta'
    )

    sd = Bike::Set::Dynamic.new(:workflow  => 'default_meta')
    def sd.meta_foo
      'abc'
    end
    assert_equal(
      'abc',
      sd[:foo],
      'workflow.DEFAULT_META should be eclipsed by meta_*()'
    )
  end

  def test_meta_tid
    tid = @sd[:tid]
    assert_match(
      Bike::REX::TID,
      tid,
      'Set::Dynamic#meta_tid should return an unique id per an instance'
    )
    assert_equal(
      tid,
      @sd[:tid],
      'Set::Dynamic#meta_tid should return the same id throughout the lifecycle of the item'
    )
    assert_not_equal(
      tid,
      Bike::Set::Dynamic.new[:tid],
      'Set::Dynamic#meta_tid should be unique to an item'
    )
  end

  def test_meta_base_path
    item = Bike::Set::Static::Folder.root.item('foo', 'main')

    Bike.current[:base] = Bike::Set::Static::Folder.root.item('foo', 'bar', 'sub')
    assert_equal(
      '/foo/bar/sub',
      item[:base_path],
      'Field#[:base_path] should return the path name of the base SD'
    )

    Bike.current[:base] = Bike::Set::Static::Folder.root.item('foo', 'bar', 'main')
    assert_equal(
      '/foo/bar',
      item[:base_path],
      "Field#[:base_path] should omit 'main' in the path"
    )
  end

  def test_meta_order
    sd = Bike::Set::Dynamic.new(
      :id       => 'foo',
      :klass    => 'set-dynamic',
      :workflow => 'contact'
    )
    assert_nil(
      sd[:order],
      'Set::Dynamic#[:order] should be nil by default'
    )

    sd = Bike::Set::Dynamic.new(
      :id       => 'foo',
      :klass    => 'set-dynamic',
      :workflow => 'blog'
    )
    assert_equal(
      '-id',
      sd[:order],
      'Set::Dynamic#[:order] should refer to the default_meta[:order]'
    )

    sd = Bike::Set::Dynamic.new(
      :id       => 'foo',
      :klass    => 'set-dynamic',
      :workflow => 'blog',
      :tokens   => ['asc']
    )
    assert_equal(
      'id',
      sd[:order],
      'Set::Dynamic#[:order] should be overriden by meta[:order]'
    )
  end

  def test_meta_href
    Bike.current[:uri] = nil

    sd = Bike::Set::Static::Folder.root.item('foo','main')
    assert_equal(
      '/foo/',
      sd[:href],
      'Set::Dynamic#meta_href should return the uri to itself'
    )

    sd = Bike::Set::Static::Folder.root.item('foo','sub')
    assert_equal(
      '/foo/sub/',
      sd[:href],
      "Set::Dynamic#meta_href should not omit steps other than 'main'"
    )

    sd = Bike::Set::Static::Folder.root.item('foo','main','20091120_0001','replies')
    assert_equal(
      '/foo/20091120_0001/replies/',
      sd[:href],
      'Set::Dynamic#meta_href should return the proper uri for a nested SD'
    )
  end

  def test_item
    @sd.load('20100131_1234' => {'name' => 'frank'})
    assert_instance_of(
      Bike::Set::Static,
      @sd.item('20100131_1234'),
      'Set::Dynamic#item should return the child set in the storage'
    )

    assert_nil(
      @sd.item('non-existent'),
      'Set::Dynamic#item should return nil when the item is not in the storage'
    )
    assert_nil(
      @sd.item(''),
      'Set::Dynamic#item should return nil when the item is not in the storage'
    )
  end

  def test_val
    @sd.load(
      '20100131_1234' => {'name' => 'frank'},
      '20100131_1235' => {'name' => 'carl'}
    )
    assert_equal(
      {
        '20100131_1234' => {'name' => 'frank'},
        '20100131_1235' => {'name' => 'carl'},
      },
      @sd.val,
      'Set::Dynamic#val without arg should return values of all items in the storage'
    )
    assert_equal(
      {'name' => 'frank'},
      @sd.val('20100131_1234'),
      'Set::Dynamic#val with an item id should return the value of the item in the storage'
    )
    assert_nil(
      @sd.val('non-existent'),
      'Set::Dynamic#val with an item id should return nil when the item is not in the storage'
    )
  end

  def test_get
    @sd.load(
      '20100131_1234' => {'name' => 'frank', 'comment' => 'bar'},
      '20100131_1235' => {'name' => 'carl', 'comment' => 'baz'}
    )
    @sd[:tmpl][:navi] = ''
    @sd.each {|item| item[:tmpl][:action_update] = '' }
    assert_equal(
      <<'_html',
<ul id="foo" class="app-blog">
  <li>frank: bar</li>
  <li>carl: baz</li>
</ul>
_html
      @sd.get,
      'Set::Dynamic#get should return the html by [:tmpl]'
    )
    assert_equal(
      <<'_html',
<ul id="foo" class="app-blog">
  <li>carl: baz</li>
</ul>
_html
      @sd.get(:conds => {:id => '20100131_1235'}),
      'Set::Dynamic#get should return the html by [:tmpl]'
    )

    @sd.each {|ss|
      ss.each {|item|
        def item._g_update(arg)
          'moo!'
        end
      }
    }
    assert_equal(
      <<'_html',
<ul id="foo" class="app-blog">
  <li>moo!: moo!</li>
</ul>
[foo-update]
_html
      @sd.get(:conds => {:id => '20100131_1235'}, :action => :update),
      'Set::Dynamic#get should pass the given action to lower items'
    )
  end

  def test_get_create
    @sd.load(
      '1234' => {'name' => 'frank', 'comment' => 'bar'},
      '1235' => {'name' => 'carl', 'comment' => 'baz'}
    )
    result = @sd.get(:action => :create)
    assert_match(
      /<input/,
      result,
      'Set::Dynamic#_g_create should return the _g_create() of a newly created item'
    )
    assert_no_match(
      /bar/,
      result,
      'Set::Dynamic#_g_create should not include the _g_create() of existing items'
    )
  end

  def test_get_empty_item
    @sd.load(
      '1234' => {}
    )

    assert_equal(
      <<'_html',
<ul id="foo" class="app-blog">
</ul>
_html
      @sd.get(:action => :read),
      'Set#_g_default should skip empty items'
    )

    assert_equal(
      <<'_html',
<ul id="foo" class="app-blog">
  <li><span class="text"><input type="text" name="name" value="" size="16" /></span>: <span class="text"><input type="text" name="comment" value="" size="64" /></span></li>
</ul>
[foo-update]
_html
      @sd.get(:action => :update),
      'Set#_g_default should not skip empty items when the action is :create or :update'
    )
  end

  def test_get_preview
    Bike.current[:base] = nil
    @sd.load(
      '20100330_1234' => {'name' => 'frank', 'comment' => 'bar'},
      '20100330_1235' => {'name' => 'carl', 'comment' => 'baz'}
    )
    assert_equal(
      <<'_html',
<ul id="foo" class="app-blog">
  <li>frank: bar<input type="hidden" name="20100330_1234.action" value="howdy" /></li>
</ul>
[foo-preview.howdy]
_html
      @sd.get(:action => :preview, :sub_action => :howdy, :conds => {:id => '20100330_1234'}),
      'Set::Dynamic#_g_preview should return _g_read + _g_submit'
    )
  end

  def test_get_by_self_reference
    ss = Bike::Set::Static.new(
      :html => '<ul class="app-attachment"><li class="model"></li>$(.pipco)</ul>'
    )
    sd = ss.item('main')
    def sd._g_submit(arg)
      ''
    end
    def sd._g_pipco(arg)
      _get_by_action_tmpl(arg) || 'PIPCO'
    end
    def sd._g_jawaka(arg)
      'JAWAKA'
    end
    sd[:tmpl][:navi] = ''

    sd[:tmpl][:pipco]  = '<foo>$(.jawaka)</foo>'
    sd[:tmpl][:jawaka] = nil
    assert_equal(
      '<ul class="app-attachment"><foo>JAWAKA</foo></ul>',
      ss.get,
      'Set::Dynamic#_get_by_self_reference should work via [:parent]._get_by_tmpl()'
    )

    sd[:tmpl][:pipco]  = '<foo>$(.jawaka)</foo>'
    sd[:tmpl][:jawaka] = 'via tmpl'
    assert_equal(
      '<ul class="app-attachment"><foo>JAWAKA</foo></ul>',
      ss.get,
      'Set::Dynamic#_get_by_self_reference should not recur'
    )

    sd[:tmpl][:pipco]  = '<foo>$(.pipco)</foo>'
    sd[:tmpl][:jawaka] = nil
    assert_nothing_raised(
      'Set::Dynamic#_get_by_self_reference should not cause an infinite reference'
    ) {
      ss.get
    }

    sd[:tmpl][:pipco]  = '<foo>$()</foo>'
    assert_nothing_raised(
      'Set::Dynamic#_get_by_self_reference should not cause an infinite reference'
    ) {
      ss.get
    }

    sd[:tmpl][:pipco]  = '<foo>$(.jawaka)</foo>'
    sd[:tmpl][:jawaka] = '<bar>$(.pipco)</bar>'
    assert_nothing_raised(
      'Set::Dynamic#_get_by_self_reference should not cause an infinite reference'
    ) {
      ss.get
    }
  end

  def test_get_by_self_reference_via_parent_tmpl
    ss = Bike::Set::Static.new(
      :html => '$(main.action_pipco)<ul class="app-attachment"></ul>'
    )
    sd = ss.item('main')
    def sd._g_submit(arg)
    end
    def sd._g_action_pipco(arg)
      'PIPCO'
    end
    sd[:tmpl][:navi] = ''

    assert_equal(
      'PIPCO<ul class="app-attachment"></ul>',
      ss.get,
      'Set::Dynamic#_get_by_self_reference should work via [:parent]._get_by_tmpl()'
    )
    assert_equal(
      '<ul class="app-attachment"></ul>',
      ss.get('main' => {:action => :create}),
      'Set::Dynamic#_get_by_self_reference should hide unused items via [:parent]._get_by_tmpl()'
    )
  end

  def test_get_by_self_reference_multiple_vars
    ss = Bike::Set::Static.new(
      :html => '<ul class="app-attachment">$(.pipco)<li class="model">$(foo=text)</li></ul>'
    )
    sd = ss.item('main')
    def sd._g_pipco(arg)
      'PIPCO'
    end
    sd[:tmpl][:navi] = ''

    assert_equal(
      '<ul class="app-attachment">PIPCO</ul>',
      ss.get,
      'Set::Dynamic#_get_by_self_reference should not be affected by previous $(.action)'
    )
  end

  def test_get_uri_prev_next
    @sd[:p_size] = 2
    @sd.load(
      '20091128_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20091129_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20091130_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20091201_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20091202_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20091203_0001' => {'name' => 'frank', 'comment' => 'bar'}
    )

    assert_equal(
      '200912/',
      @sd.send(
        :_g_uri_prev,
        :conds => {:d => '200912', :p => '2'}
      ),
      'Set::Dynamic#_g_uri_prev should return the previous uri for the given conds'
    )
    assert_nil(
      @sd.send(
        :_g_uri_next,
        :conds => {:d => '200912', :p => '2'}
      ),
      'Set::Dynamic#_g_uri_next should return nil if there is no next conds'
    )

    assert_equal(
      '200911/p=2/',
      @sd.send(
        :_g_uri_prev,
        :conds => {:d => '200912', :p => '1'}
      ),
      'Set::Dynamic#_g_uri_prev should return the previous uri for the given conds'
    )
    assert_equal(
      '200911/',
      @sd.send(
        :_g_uri_prev,
        :conds => {:d => '200911', :p => '2'}
      ),
      'Set::Dynamic#_g_uri_prev should return the previous uri for the given conds'
    )
    assert_equal(
      '200912/',
      @sd.send(
        :_g_uri_next,
        :conds => {:d => '200911', :p => '2'}
      ),
      'Set::Dynamic#_g_uri_next should return the next uri for the given conds'
    )
    assert_nil(
      @sd.send(
        :_g_uri_prev,
        :conds => {:d => '200911', :p => '1'}
      ),
      'Set::Dynamic#_g_uri_prev should return nil if there is no previous conds'
    )

    assert_equal(
      '200911/p=2/read_detail.html',
      @sd.send(
        :_g_uri_prev,
        {
          :conds       => {:d => '200912', :p => '1'},
          :orig_action => :read,
          :sub_action  => :detail,
        }
      ),
      'Set::Dynamic#_g_uri_prev should include the original action if the action is special'
    )
    assert_equal(
      '200912/read_detail.html',
      @sd.send(
        :_g_uri_next,
        {
          :conds       => {:d => '200911', :p => '2'},
          :orig_action => :read,
          :sub_action  => :detail,
        }
      ),
      'Set::Dynamic#_g_uri_next should include the original action if the action is special'
    )

    @sd[:tmpl][:navi] = '$(.uri_prev)'
    assert_equal(
      '200911/',
      @sd.send(
        :_get_by_self_reference,
        :action      => :navi,
        :conds       => {:d => '200911', :p => '2'},
        :orig_action => :read
      ),
      'Set::Dynamic#_g_navi should pass the conds to the subsequent calls to _g_*()'
    )
  end

  def test_recurring_action_tmpl
    @sd.load(
      '20091128_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20091129_0001' => {'name' => 'frank', 'comment' => 'bar'}
    )
    @sd[:tmpl][:navi] = '$(.navi)'

    result = nil
    assert_nothing_raised(
      'Set::Dynamic#_g_navi should not call itself recursively'
    ) {
      result = @sd.send(
        :_get_by_self_reference,
        :action      => :navi,
        :conds       => {:d => '20091128'},
        :orig_action => :read
      )
    }
    assert_equal(
      '$(.navi)',
      result,
      'Set::Dynamic#_g_navi should ignore $(.navi)'
    )

    @sd[:tmpl][:navi] = nil
    @sd[:tmpl][:navi_next] = '$(.navi)'
    assert_nothing_raised(
      'Set::Dynamic#_g_navi should not call itself recursively'
    ) {
      result = @sd.send(
        :_get_by_self_reference,
        :action      => :navi,
        :conds       => {:d => '20091128'},
        :orig_action => :read
      )
    }
    assert_match(
      /\$\(\.navi\)/,
      result,
      'Set::Dynamic#_g_navi_next should ignore $(.navi)'
    )
  end

  def test_item_arg
    root_arg = {
      :action => :read,
      'foo'   => {
        :action => :update,
        :conds  => {:d => '2010'},
        'bar'   => {
          :action => :delete,
        },
      },
      'baz'   => {
        'qux' => {:action => :create},
      },
    }

    assert_equal(
      {
        :p_action => :read,
        :action   => :update,
        :conds    => {:d => '2010'},
        'bar'     => {
          :action => :delete,
        },
      },
      @sd.send(
        :item_arg,
        root_arg,
        'foo'
      ),
      'Set#item_arg should return a partial hash of the root arg'
    )
    assert_equal(
      {
        :p_action => :update,
        :action   => :delete,
      },
      @sd.send(
        :item_arg,
        root_arg,
        ['foo', 'bar']
      ),
      'Set#item_arg should dig into multiple steps'
    )
    assert_equal(
      {
        :p_action => :read,
        :action   => :read,
        'qux'     => {:action => :create},
      },
      @sd.send(
        :item_arg,
        root_arg,
        ['baz']
      ),
      'Set#item_arg should supplement item_arg[:action]'
    )
    assert_equal(
      {
        :p_action => :read,
        :action   => :create,
      },
      @sd.send(
        :item_arg,
        root_arg,
        ['baz', 'qux']
      ),
      'Set#item_arg should supplement item_arg[:p_action]'
    )
    assert_equal(
      {
        :p_action => :read,
        :action   => :read,
      },
      @sd.send(
        :item_arg,
        root_arg,
        ['baz', 'non-existent']
      ),
      'Set#item_arg should supplement item_arg[:action] & item_arg[:p_action]'
    )
  end

  def test_uri_p
    @sd.load(
      '20091128_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20091129_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20091130_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20091201_0001' => {'name' => 'frank', 'comment' => 'bar'}
    )

    @sd[:p_size] = 2
    assert_equal(
      ['200911/', '200911/p=2/'],
      @sd.send(
        :_uri_p,
        :conds => {:d => '200911', :p => '1'}
      ),
      'Set::Dynamic#_uri_p should return the array of the sibling conds'
    )

    @sd[:p_size] = nil
    assert_nil(
      @sd.send(
        :_uri_p,
        :conds => {:d => '200911'}
      ),
      'Set::Dynamic#_uri_p should return nil if the siblings are not :p'
    )

    @sd[:p_size] = 2
    assert_nil(
      @sd.send(
        :_uri_p,
        :conds => {:d => '200911', :id => '20091129_0001'}
      ),
      'Set::Dynamic#_uri_p should return nil if the siblings are not :p'
    )
    assert_nil(
      @sd.send(
        :_uri_p,
        :conds => {:d => '200911', :p => '1', :id => '20091129_0001'}
      ),
      'Set::Dynamic#_uri_p should return nil if the siblings are not :p'
    )
  end

  def test_g_view_ym
    @sd[:order] = 'id'
    @sd.load(
      '20091128_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20091129_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20091130_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20091201_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20100111_0001' => {'name' => 'frank', 'comment' => 'bar'}
    )
    assert_equal(
      <<'_html',
<div class="view_ym">
  <span class="y">
    2009 |
    <span class="m"><a href="/foo/200911/">Nov</a></span>
    <span class="m"><a href="/foo/200912/">Dec</a></span>
    <br/>
  </span>
  <span class="y">
    2010 |
    <span class="m"><a href="/foo/201001/">Jan</a></span>
    <br/>
  </span>
</div>
_html
      @sd.send(
        :_g_view_ym,
        {:conds => {}}
      ),
      'Set::Dynamic#_g_view_ym should return the available ym conds'
    )

    @sd[:order] = '-id'
    @sd.load(
      '20091128_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20091129_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20091130_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20091201_0001' => {'name' => 'frank', 'comment' => 'bar'},
      '20100111_0001' => {'name' => 'frank', 'comment' => 'bar'}
    )
    assert_equal(
      <<'_html',
<div class="view_ym">
  <span class="y">
    2009 |
    <span class="m"><a href="/foo/200911/p=last/">Nov</a></span>
    <span class="m"><a href="/foo/200912/p=last/">Dec</a></span>
    <br/>
  </span>
  <span class="y">
    2010 |
    <span class="m"><a href="/foo/201001/p=last/">Jan</a></span>
    <br/>
  </span>
</div>
_html
      @sd.send(
        :_g_view_ym,
        {:conds => {}}
      ),
      'Set::Dynamic#_g_view_ym should refer to [:order]'
    )

    @sd[:order] = 'id'
    assert_equal(
      <<'_html',
<div class="view_ym">
  <span class="y">
    2009 |
    <span class="m"><a href="/foo/200911/">Nov</a></span>
    <span class="m"><span class="current">Dec</span></span>
    <br/>
  </span>
  <span class="y">
    2010 |
    <span class="m"><a href="/foo/201001/">Jan</a></span>
    <br/>
  </span>
</div>
_html
      @sd.send(
        :_g_view_ym,
        {:conds => {:d => '200912'}}
      ),
      'Set::Dynamic#_g_view_ym should distinguish the current cond[:d] if available'
    )
  end

  def test_g_submit
    Bike.client = nil
    @sd = Bike::Set::Dynamic.new(
      :klass    => 'set-dynamic',
      :workflow => 'blog',
      :tmpl     => {:index => '$(.submit)'},
      :item     => {
        'default' => Bike::Parser.parse_html(<<'_html')
  <li>$(name = text 32 :'nobody'): $(comment = text 64 :'hi.')$(.hidden)</li>
_html
      }
    ).load(
      '_001'          => {'name' => 'frank', 'comment' => 'bar'},
      '20100401_0001' => {'name' => 'frank', 'comment' => 'bar'}
    )
    wf = @sd.workflow

    def wf.permit?(roles, action)
      true
    end
    @sd[:preview] = nil

    assert_equal(
      <<'_html',
<div class="submit">
  <input name=".status-public" type="submit" value="create" />
</div>
_html
      @sd.get(:action => :update, :conds => {:id => '_001'}),
      'Set#_g_submit should not return preview_delete when there is only new items'
    )
    @sd[:preview] = nil
    assert_equal(
      <<'_html',
<div class="submit">
  <input name=".status-public" type="submit" value="update" />
  <input name=".action-preview_delete" type="submit" value="delete..." />
</div>
_html
      @sd.get(:action => :update, :conds => {:id => '20100401_0001'}),
      'Set#_g_submit should return buttons according to the permission, meta and orig_action'
    )
    @sd[:preview] = :optional
    assert_equal(
      <<'_html',
<div class="submit">
  <input name=".status-public" type="submit" value="update" />
  <input name=".action-preview_update" type="submit" value="preview" />
  <input name=".action-preview_delete" type="submit" value="delete..." />
</div>
_html
      @sd.get(:action => :update, :conds => {:id => '20100401_0001'}),
      'Set#_g_submit should return buttons according to the permission, meta and orig_action'
    )
    @sd[:preview] = :mandatory
    assert_equal(
      <<'_html',
<div class="submit">
  <input name=".action-preview_update" type="submit" value="preview" />
  <input name=".action-preview_delete" type="submit" value="delete..." />
</div>
_html
      @sd.get(:action => :update, :conds => {:id => '20100401_0001'}),
      'Set#_g_submit should return buttons according to the permission, meta and orig_action'
    )
    assert_equal(
      <<'_html',
<div class="submit">
  <input name=".status-public" type="submit" value="update" />
</div>
_html
      @sd.get(:action => :preview, :sub_action => :update),
      'Set#_g_submit should not show preview buttons when the orig_action is :preview'
    )
    assert_equal(
      <<'_html',
<div class="submit">
  <input name=".status-public" type="submit" value="delete" />
</div>
_html
      @sd.get(:action => :preview, :sub_action => :delete),
      'Set#_g_submit should not show preview buttons when the orig_action is :preview'
    )

    def wf.permit?(roles, action)
      true unless action == :delete
    end
    @sd[:preview] = nil
    assert_equal(
      <<'_html',
<div class="submit">
  <input name=".status-public" type="submit" value="update" />
</div>
_html
      @sd.get(:action => :update, :conds => {:id => '20100401_0001'}),
      'Set#_g_submit should return buttons according to the permission, meta and orig_action'
    )
    @sd[:preview] = :optional
    assert_equal(
      <<'_html',
<div class="submit">
  <input name=".status-public" type="submit" value="update" />
  <input name=".action-preview_update" type="submit" value="preview" />
</div>
_html
      @sd.get(:action => :update, :conds => {:id => '20100401_0001'}),
      'Set#_g_submit should return buttons according to the permission, meta and orig_action'
    )
    @sd[:preview] = :mandatory
    assert_equal(
      <<'_html',
<div class="submit">
  <input name=".action-preview_update" type="submit" value="preview" />
</div>
_html
      @sd.get(:action => :update, :conds => {:id => '20100401_0001'}),
      'Set#_g_submit should return buttons according to the permission, meta and orig_action'
    )
    assert_equal(
      <<'_html',
<div class="submit">
  <input name=".status-public" type="submit" value="update" />
</div>
_html
      @sd.get(:action => :preview, :sub_action => :update),
      'Set#_g_submit should not show preview buttons when the orig_action is :preview'
    )

    def wf.permit?(roles, action)
      true unless action == :update
    end
    @sd[:preview] = nil
    assert_equal(
      <<'_html',
<div class="submit">
  <input name=".status-public" type="submit" value="delete" />
</div>
_html
      @sd.get(:action => :preview, :sub_action => :delete),
      'Set#_g_submit should not show preview buttons when the orig_action is :preview'
    )
  end

  def test_post
    @sd.post(:create, '1234' => {'name' => 'carl'})
    assert_equal(
      :create,
      @sd.action,
      'Set::Dynamic#post should set @action'
    )

    @sd.commit
    assert_equal(
      :create,
      @sd.result,
      'Set::Dynamic#commit should set @result'
    )

    @sd.post(:update, '1234' => {'name' => 'frank'})
    assert_nil(
      @sd.result,
      'Set::Dynamic#post should reset @result'
    )
  end

  def test_post_multiple_attachments
    Bike.client = 'root'
    sd = Bike::Set::Static::Folder.root.item('t_attachment', 'main')
    sd.storage.clear

    # create an attachment item
    sd.update(
      '_1' => {
        'files' => {'_1' => {:action => :create, 'file' => 'foo'}},
      }
    )
    sd.commit :temp
    first_id = sd.result.values.first.item('files').val.keys.sort.first
    assert_equal(
      {
        first_id => {'file' => 'foo'},
      },
      sd.result.values.first.item('files').val,
      'Workflow::Attachment should keep the first item'
    )

    # create the second attachment
    sd.update(
      '_1' => {
        'files' => {'_1' => {:action => :create, 'file' => 'bar'}},
      }
    )
    sd.commit :temp
    second_id = sd.result.values.first.item('files').val.keys.sort.last

    assert_equal(
      first_id.succ,
      second_id,
      'Workflow::Attachment should not overwrite the first file item'
    )
    assert_equal(
      {
        first_id  => {'file' => 'foo'},
        second_id => {'file' => 'bar'},
      },
      sd.result.values.first.item('files').val,
      'Workflow::Attachment should keep both the first item and the second item'
    )

    sd.commit :persistent
    baz_id = sd.result.values.first[:id]

    item = Bike::Set::Static::Folder.root.item('t_attachment', 'main', baz_id, 'files', first_id, 'file')
    assert_equal(
      'foo',
      item.val,
      'Workflow::Attachment should store the body of the first file item'
    )

    item = Bike::Set::Static::Folder.root.item('t_attachment', 'main', baz_id, 'files', second_id, 'file')
    assert_equal(
      'bar',
      item.val,
      'Workflow::Attachment should store the body of the second file item'
    )
  end

  def test_load_default
  end

  def test_load
    @sd.load('1235' => {'name' => 'carl'})
    assert_equal(
      {'1235' => {'name' => 'carl'}},
      @sd.val,
      'Set::Dynamic#load should load the storage with the given values'
    )
    @sd.load('1234' => {'name' => 'frank'})
    assert_equal(
      {'1234' => {'name' => 'frank'}},
      @sd.val,
      'Set::Dynamic#load should overwrite all values in the storage'
    )
  end

  def test_create
    s = @sd.storage
    def s.new_id(v = {})
      @c ||= 0
      (@c += 1).to_s
    end

    @sd.create({})
    assert_equal(
      {},
      @sd.val,
      'Set::Dynamic#create should build the empty storage by default'
    )

    @sd.create('_1235' => {'name' => 'carl'})
    assert_equal(
      {'_owner' => 'root', 'name' => 'carl', 'comment' => 'hi.'},
      @sd.item('_1235').val,
      'Set::Dynamic#create should create the new items in the empty storage'
    )
    @sd.commit
    assert_equal(
      {'1' => {'_owner' => 'root', 'name' => 'carl', 'comment' => 'hi.'}},
      @sd.val,
      'Set::Dynamic#create should create the new items in the empty storage'
    )

    @sd.create('_1234' => {'name' => 'frank'})
    assert_equal(
      {'_owner' => 'root', 'name' => 'frank', 'comment' => 'hi.'},
      @sd.item('_1234').val,
      'Set::Dynamic#create should create the new items in the empty storage'
    )
    assert_equal(
      {},
      @sd.val,
      'Set::Dynamic#val should be empty before the commit'
    )
    @sd.commit
    assert_equal(
      {'2' => {'_owner' => 'root', 'name' => 'frank', 'comment' => 'hi.'}},
      @sd.val,
      'Set::Dynamic#create should overwrite all items in the storage'
    )

    @sd.create('_2' => {'name' => 'frank'}, '_1' => {'name' => 'bobby'})
    assert_equal(
      {},
      @sd.val,
      'Set::Dynamic#val should be empty before the commit'
    )
    @sd.commit
    assert_equal(
      {
        '4' => {'_owner' => 'root', 'name' => 'frank', 'comment' => 'hi.'},
        '3' => {'_owner' => 'root', 'name' => 'bobby', 'comment' => 'hi.'},
      },
      @sd.val,
      'Set::Dynamic#create should create multiple items in the empty storage'
    )
  end

  def test_update
    @sd.load(
      '20091122_1234' => {'name' => 'frank', 'comment' => 'bar'},
      '20091122_1235' => {'name' => 'carl', 'comment' => 'baz'}
    )
    s = @sd.storage
    def s.new_id(v = {})
      'new!'
    end

    # update an item
    @sd.update('20091122_1234' => {'comment' => 'qux'})
    assert_equal(
      {'name' => 'frank', 'comment' => 'qux'},
      @sd.item('20091122_1234').val,
      'Set::Dynamic#update should update the values of the item instance'
    )
    assert_equal(
      :update,
      @sd.item('20091122_1234').action,
      'Set::Dynamic#update should set a proper action on the item'
    )
    assert_equal(
      nil,
      @sd.item('20091122_1234', 'name').action,
      'Set::Dynamic#update should set a proper action on the item'
    )
    assert_equal(
      :update,
      @sd.item('20091122_1234', 'comment').action,
      'Set::Dynamic#update should set a proper action on the item'
    )

    # create an item
    @sd.update('_1236' => {'name' => 'roy'})
    assert_equal(
      {'_owner' => 'root', 'name' => 'roy', 'comment' => 'hi.'},
      @sd.item('_1236').val,
      'Set::Dynamic#update should update the values of the item instance'
    )
    assert_equal(
      :create,
      @sd.item('_1236').action,
      'Set::Dynamic#update should set a proper action on the item'
    )
    assert_equal(
      :create,
      @sd.item('_1236', 'name').action,
      'Set::Dynamic#update should set a proper action on the item'
    )
    assert_equal(
      nil,
      @sd.item('_1236', 'comment').action,
      'Set::Dynamic#update should set a proper action on the item'
    )

    # delete an item
    @sd.update('20091122_1235' => {:action => :delete})
    assert_equal(
      {'name' => 'carl', 'comment' => 'baz'},
      @sd.item('20091122_1235').val,
      'Set::Dynamic#update should not update the values of the item when deleting'
    )
    assert_equal(
      :delete,
      @sd.item('20091122_1235').action,
      'Set::Dynamic#update should set a proper action on the item'
    )

    # before the commit
    assert_equal(
      :update,
      @sd.action,
      'Set::Dynamic#update should set a proper action'
    )
    assert_nil(
      @sd.result,
      'Set::Dynamic#result should return nil before the commit'
    )
    assert_equal(
      {
        '20091122_1234' => {'name' => 'frank', 'comment' => 'bar'},
        '20091122_1235' => {'name' => 'carl', 'comment' => 'baz'},
      },
      @sd.val,
      'Set::Dynamic#update should not touch the original values in the storage'
    )

    @sd.commit :temp

    # after the commit
    assert(
      @sd.pending?,
      'Set::Dynamic#commit(:temp) should keep the pending status of the items'
    )
    assert_equal(
      {
        '20091122_1234' => {'name' => 'frank', 'comment' => 'qux'},
        'new!'          => {'name' => 'roy',  'comment' => 'hi.', '_owner' => 'root'},
      },
      @sd.val,
      'Set::Dynamic#commit should update the original values in the storage'
    )
    assert_equal(
      {
        '20091122_1234' => @sd.item('20091122_1234'),
        '20091122_1235' => @sd.instance_eval { @item_object['20091122_1235'] },
        '_1236'         => @sd.item('_1236'),
      },
      @sd.result,
      'Set::Dynamic#result should return a hash of the committed items when :update'
    ) if nil
    assert_equal(
      {'comment' => @sd.item('20091122_1234', 'comment')},
      @sd.item('20091122_1234').result,
      'Set::Static#result should return a hash of the committed items when :update'
    )
    assert_equal(
      :delete,
      @sd.result['20091122_1235'].result,
      'Set::Static#result should return the committed action unless :update'
    )
    assert_equal(
      :create,
      @sd.result['_1236'].result,
      'Set::Static#result should return the committed action unless :update'
    )
  end

  def test_update_with_eclectic_val
    @sd.load(
      '20091122_1234' => {'name' => 'frank', 'comment' => 'bar'},
      '20091122_1235' => {'name' => 'carl', 'comment' => 'baz'}
    )
    s = @sd.storage

    assert_nothing_raised(
      'Set::Dynamic#update should work with values other than sub-items'
    ) {
      @sd.update('20091122_1234' => {'comment' => 'qux'}, :conds => {}, :action => nil)
    }
    assert_equal(
      {'name' => 'frank', 'comment' => 'qux'},
      @sd.item('20091122_1234').val,
      'Set::Dynamic#update should update the values of the item instance'
    )
  end

  def test_delete
    @sd.delete
    assert_equal(
      :delete,
      @sd.action,
      'Set::Dynamic#delete should set @action'
    )
  end

  def test_delete_invalid_item
    @sd.load(
      '20091122_1234' => {'name' => 'frank', 'comment' => 'bar'}
    )

    # update with invalid value
    @sd.update(
      '20091122_1234' => {'name' => 'too looooooooooooooooooooong'}
    )
    assert(!@sd.valid?)

    # delete the invalid item
    @sd.update(
      '20091122_1234' => {:action => :delete}
    )
    assert_equal(
      {},
      @sd.errors,
      'Set::Dynamic#errors should ignore items with :delete action'
    )

    @sd.commit
    assert(
      @sd.valid?,
      'Set::Dynamic#commit should be able to delete an invalid item'
    )
    assert_equal(
      {},
      @sd.val,
      'Set::Dynamic#commit should be able to delete an invalid item'
    )
  end

  def test_get_by_nobody
    @sd.load(
      '20091122_0001' => {'_owner' => 'frank', 'comment' => 'bar'},
      '20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
    )
    Bike.client = nil

    arg = {:action => :update, :conds => {:d => '2009'}}
    assert_raise(
      Bike::Error::Forbidden,
      'Set::Dynamic#get should raise Error::Forbidden when sd[:client] is nobody'
    ) {
      @sd.get arg
    }
  end

  def test_post_by_nobody
    @sd.load(
      '20091122_0001' => {'_owner' => 'frank', 'comment' => 'bar'},
      '20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
    )
    Bike.client = nil

    assert_raise(
      Bike::Error::Forbidden,
      "'nobody' should not create a new item"
    ) {
      @sd.update('_0001' => {'comment' => 'qux'})
    }
    assert_raise(
      Bike::Error::Forbidden,
      "'nobody' should not update frank's item"
    ) {
      @sd.update('20091122_0001' => {'comment' => 'qux'})
    }
    assert_raise(
      Bike::Error::Forbidden,
      "'nobody' should not delete frank's item"
    ) {
      @sd.update('20091122_0001' => {:action => :delete})
    }
  end

  def test_get_by_carl
    @sd.load(
      '20091122_0001' => {'_owner' => 'frank', 'comment' => 'bar'},
      '20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
    )
    Bike.client = 'carl' # carl is not the member of the group

    arg = {}
    @sd.get arg
    assert_equal(
      :read,
      arg[:action],
      'Set::Dynamic#get should set the default action'
    )

    arg = {:action => :create}
    assert_raise(
      Bike::Error::Forbidden,
      'Set::Dynamic#get should raise Error::Forbidden when an action is given but forbidden'
    ) {
      @sd.get arg
    }

    arg = {:action => :update, :conds => {:d => '2009'}}
    assert_raise(
      Bike::Error::Forbidden,
      'Set::Dynamic#get should not keep the partially-permitted action'
    ) {
      @sd.get arg
    }

    arg = {:action => :update, :conds => {:id => '20091122_0002'}}
    @sd.get arg
    assert_equal(
      :update,
      arg[:action],
      'Set::Dynamic#get should keep the permitted action'
    )
  end

  def test_post_by_carl
    @sd.load(
      '20091122_0001' => {'_owner' => 'frank', 'comment' => 'bar'},
      '20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
    )
    Bike.client = 'carl' # carl is not the member of the group

    assert_raise(
      Bike::Error::Forbidden,
      'carl should not create a new item'
    ) {
      @sd.update('_0001' => {'comment' => 'qux'})
    }
    assert_raise(
      Bike::Error::Forbidden,
      "carl should not update frank's item"
    ) {
      @sd.update('20091122_0001' => {'comment' => 'qux'})
    }
    assert_nothing_raised(
      'carl should be able to update his own item'
    ) {
      @sd.update('20091122_0002' => {'comment' => 'qux'})
    }
    assert_raise(
      Bike::Error::Forbidden,
      "carl should not delete frank's item"
    ) {
      @sd.update('20091122_0001' => {:action => :delete})
    }
  end

  def test_get_by_roy
    @sd.load(
      '20091122_0001' => {'_owner' => 'frank', 'comment' => 'bar'},
      '20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
    )
    Bike.client = 'roy' # roy belongs to the group

    arg = {:action => :create}
    @sd.get arg
    assert_equal(
      :create,
      arg[:action],
      'Set::Dynamic#get should keep the permitted action'
    )

    arg = {:action => :delete, :conds => {:d => '2009'}}
    assert_raise(
      Bike::Error::Forbidden,
      'Set::Dynamic#get should raise Error::Forbidden when an action is given but forbidden'
    ) {
      @sd.get arg
    }
  end

  def test_post_by_roy
    @sd.load(
      '20091122_0001' => {'_owner' => 'frank', 'comment' => 'bar'},
      '20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
    )
    Bike.client = 'roy' # roy belongs to the group

    assert_nothing_raised(
      'roy should be able to create a new item'
    ) {
      @sd.update('_0001' => {'comment' => 'qux'})
    }
    assert_raise(
      Bike::Error::Forbidden,
      "roy should not update frank's item"
    ) {
      @sd.update('20091122_0001' => {'comment' => 'qux'})
    }
    assert_raise(
      Bike::Error::Forbidden,
      "roy should not delete frank's item"
    ) {
      @sd.update('20091122_0001' => {:action => :delete})
    }
  end

  def test_get_by_root
    @sd.load(
      '20091122_0001' => {'_owner' => 'frank', 'comment' => 'bar'},
      '20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
    )
    Bike.client = 'root' # root is the admin

    arg = {:action => :create, :db => 1}
    @sd.get arg
    assert_equal(
      :create,
      arg[:action],
      'Set::Dynamic#get should keep the permitted action'
    )

    arg = {:action => :delete, :conds => {:d => '2009'}}
    @sd.get arg
    assert_equal(
      :delete,
      arg[:action],
      'Set::Dynamic#get should keep the permitted action'
    )
  end

  def test_post_by_root
    @sd.load(
      '20091122_0001' => {'_owner' => 'frank', 'comment' => 'bar'},
      '20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
    )
    Bike.client = 'root' # root is the admin

    assert_nothing_raised(
      'frank should be able to create a new item'
    ) {
      @sd.update('_0001' => {'comment' => 'qux'})
    }
    assert_nothing_raised(
      'frank should be able to update his own item'
    ) {
      @sd.update('20091122_0001' => {'comment' => 'qux'})
    }
    assert_nothing_raised(
      "frank should be able to update carl's item"
    ) {
      @sd.update('20091122_0002' => {'comment' => 'qux'})
    }
    assert_nothing_raised(
      'frank should be able to delete his own item'
    ) {
      @sd.update('20091122_0001' => {:action => :delete})
    }
    assert_nothing_raised(
      "frank should be able to delete carl's item"
    ) {
      @sd.update('20091122_0002' => {:action => :delete})
    }
  end

end
