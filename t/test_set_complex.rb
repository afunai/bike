# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class TC_Set_Complex < Test::Unit::TestCase

  class ::Runo::Set::Dynamic
    def _g_vegetable(arg)
      "'potato'"
    end
  end

  class ::Runo::Workflow::Pipco < ::Runo::Workflow
    DEFAULT_SUB_ITEMS = {
      '_owner' => {:klass => 'meta-owner'},
    }
    PERM = {
      :create    => 0b11000,
      :read      => 0b11110,
      :update    => 0b11100,
      :delete    => 0b10100,
    }
    def _g_submit(arg)
      '[pipco]'
    end
  end

  class ::Runo::Tomago < ::Runo::Field
    def _get(arg)
      args = arg.keys.collect {|k| "#{k}=#{arg[k]}" }.sort
      "'#{val}'(#{args.join ', '})"
    end
  end

  def setup
    # Set::Dynamic of Set::Static of (Scalar and (Set::Dynamic of Set::Static of Scalar))
    @sd = Runo::Set::Dynamic.new(
      :id       => 'main',
      :klass    => 'set-dynamic',
      :workflow => 'pipco',
      :group    => ['roy', 'don'],
      :tmpl     => {
        :index => <<'_tmpl'.chomp,
<ul id="@(name)" class="app-pipco">
$()</ul>
$(.navi)$(.submit)$(.action_create)
_tmpl
      },
      :item     => {
        'default' => Runo::Parser.parse_html(<<'_html')
  <li id="@(name)">
    $(name = tomago 32 :'nobody'): $(comment = tomago 64 :'hello.')
    <ul id="files" class="app-attachment">
      <li id="@(name)">$(file = tomago :'foo.jpg')</li>
    </ul>
    <ul id="replies" class="app-pipco">
      <li id="@(name)">$(reply = tomago :'hi.')</li>
    </ul>
    $(replies.vegetable)
  </li>
_html
      }
    )
    @sd.load(
      '20091123_0001' => {
        '_owner'  => 'carl',
        'name'    => 'CZ',
        'comment' => 'oops',
        'files'   => {
          '20091123_0001' => {'file' => 'carl1.jpg'},
          '20091123_0002' => {'file' => 'carl2.jpg'},
        },
        'replies'   => {
          '20091125_0001' => {'_owner' => 'bobby', 'reply' => 'howdy.'},
        },
      },
      '20091123_0002' => {
        '_owner'  => 'roy',
        'name'    => 'RE',
        'comment' => 'wee',
        'files'   => {
          '20091123_0001' => {'file' => 'roy.png'},
        },
        'replies'   => {
          '20091125_0001' => {'_owner' => 'don', 'reply' => 'ho ho.'},
          '20091125_0002' => {'_owner' => 'roy', 'reply' => 'oops.'},
        },
      }
    )

    [
      @sd,
      @sd.item('20091123_0001', 'files'),
      @sd.item('20091123_0001', 'replies'),
      @sd.item('20091123_0002', 'files'),
      @sd.item('20091123_0002', 'replies'),
    ].each {|sd|
      sd[:tmpl][:action_create] = ''
      sd[:tmpl][:navi] = ''
      sd[:tmpl][:submit_create] = '[c]'
      sd[:tmpl][:submit_delete] = '[d]'
      def sd._g_submit(arg)
        "[#{my[:id]}-#{arg[:orig_action]}]\n"
      end

      sd.each {|item|
        item[:tmpl][:action_update] = ''
      }
    }
  end

  def teardown
    Runo.client = nil
  end

  def test_get_default
    Runo.client = 'root' #nil
    result = @sd.get

    assert_match(
      /'potato'/,
      result,
      'Set#get should include $(foo.baz) whenever the action :baz is permitted'
    )
    assert_equal(
      <<'_html',
<ul id="main" class="app-pipco">
  <li id="main-20091123_0001">
    'CZ'(action=read, p_action=read): 'oops'(action=read, p_action=read)
    <ul id="main-20091123_0001-files" class="app-attachment">
      <li id="main-20091123_0001-files-20091123_0001">'carl1.jpg'(action=read, p_action=read)</li>
      <li id="main-20091123_0001-files-20091123_0002">'carl2.jpg'(action=read, p_action=read)</li>
    </ul>
    <ul id="main-20091123_0001-replies" class="app-pipco">
      <li id="main-20091123_0001-replies-20091125_0001"><a href="/20091123_0001/replies/20091125/1/update.html">'howdy.'(action=read, p_action=read)</a></li>
    </ul>
    'potato'
  </li>
  <li id="main-20091123_0002">
    'RE'(action=read, p_action=read): 'wee'(action=read, p_action=read)
    <ul id="main-20091123_0002-files" class="app-attachment">
      <li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=read, p_action=read)</li>
    </ul>
    <ul id="main-20091123_0002-replies" class="app-pipco">
      <li id="main-20091123_0002-replies-20091125_0001"><a href="/20091123_0002/replies/20091125/1/update.html">'ho ho.'(action=read, p_action=read)</a></li>
      <li id="main-20091123_0002-replies-20091125_0002"><a href="/20091123_0002/replies/20091125/2/update.html">'oops.'(action=read, p_action=read)</a></li>
    </ul>
    'potato'
  </li>
</ul>
_html
      result,
      'Set#get should work recursively as a part of the complex'
    )
  end

  def test_get_with_parent_action
    Runo.client = 'root'
    result = @sd.get(:action => :update)

    assert_match(
      /id="main-20091123_0001-files"/,
      result,
      'Set::Dynamic#get(:action => :update) should include child attachments'
    )
    assert_no_match(
      /id="main-20091123_0001-replies"/,
      result,
      'Set::Dynamic#get(:action => :update) should not include child apps'
    )
    assert_no_match(
      /'potato'/,
      result,
      'Set::Dynamic#get(:action => :update) should not include any value of child apps'
    )
    assert_no_match(
      /<form.+<form/m,
      result,
      'Set::Dynamic#get(:action => :update) should not return nested forms'
    )
    assert_equal(
      <<'_html',
<ul id="main" class="app-pipco">
  <li id="main-20091123_0001">
    'CZ'(action=update, p_action=update): 'oops'(action=update, p_action=update)
    <ul id="main-20091123_0001-files" class="app-attachment">
      <li id="main-20091123_0001-files-20091123_0001">'carl1.jpg'(action=update, p_action=update)[d]</li>
      <li id="main-20091123_0001-files-20091123_0002">'carl2.jpg'(action=update, p_action=update)[d]</li>
      <li id="main-20091123_0001-files-_001">'foo.jpg'(action=create, p_action=create)[c]</li>
    </ul>
  </li>
  <li id="main-20091123_0002">
    'RE'(action=update, p_action=update): 'wee'(action=update, p_action=update)
    <ul id="main-20091123_0002-files" class="app-attachment">
      <li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=update, p_action=update)[d]</li>
      <li id="main-20091123_0002-files-_001">'foo.jpg'(action=create, p_action=create)[c]</li>
    </ul>
  </li>
</ul>
[main-update]
_html
      result,
      'Set#get should distribute the action to its items'
    )
  end

  def test_get_with_partial_permission
    Runo.client = 'carl' # can edit only his own item

    assert_raise(
      Runo::Error::Forbidden,
      'Field#get should raise Error::Forbidden when an action is given but forbidden'
    ) {
      @sd.get(:action => :update, :conds => {:id => '20091123_0002'})
    }

    @sd.item('20091123_0002', 'comment')[:owner] = 'carl' # enclave in roy's item

    assert_raise(
      Runo::Error::Forbidden,
      'Field#get should not allow partially permitted get'
    ) {
      @sd.get(:action => :update, :conds => {:id => '20091123_0002'})
    }
  end

  def test_get_with_partial_action
    Runo.client = 'root'

    Runo.current[:base] = @sd.item('20091123_0002', 'replies')
    Runo.base[:tid] = '123.45'

    result = @sd.get(
      '20091123_0002' => {
        'replies' => {
          :action => :update,
          :conds  => {:id => '20091125_0002'},
        },
      }
    )
    assert_equal(
      <<_html,
<ul id="main" class="app-pipco">
  <li id="main-20091123_0001">
    'CZ'(action=read, p_action=read): 'oops'(action=read, p_action=read)
    <ul id="main-20091123_0001-files" class="app-attachment">
      <li id="main-20091123_0001-files-20091123_0001">'carl1.jpg'(action=read, p_action=read)</li>
      <li id="main-20091123_0001-files-20091123_0002">'carl2.jpg'(action=read, p_action=read)</li>
    </ul>
    <ul id="main-20091123_0001-replies" class="app-pipco">
      <li id="main-20091123_0001-replies-20091125_0001"><a href="/20091123_0001/replies/20091125/1/update.html">'howdy.'(action=read, p_action=read)</a></li>
    </ul>
    'potato'
  </li>
  <li id="main-20091123_0002">
    'RE'(action=read, p_action=read): 'wee'(action=read, p_action=read)
    <ul id="main-20091123_0002-files" class="app-attachment">
      <li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=read, p_action=read)</li>
    </ul>
<form id="form_main-20091123_0002-replies" method="post" enctype="multipart/form-data" action="/20091123_0002/replies/123.45/update.html">
<input name="_token" type="hidden" value="#{Runo.token}" />
    <ul id="main-20091123_0002-replies" class="app-pipco">
      <li id="main-20091123_0002-replies-20091125_0002"><a>'oops.'(action=update, p_action=update)</a></li>
    </ul>
[replies-update]
</form>
    'potato'
  </li>
</ul>
_html
      result,
      'Field#get should be able to handle a partial action'
    )

    result = @sd.get(
      :conds => {:id => '20091123_0002'},
      '20091123_0002' => {
        'replies' => {
          :action => :update,
          :conds  => {:id => '20091125_0002'},
        },
      }
    )
    assert_equal(
      <<_html,
<ul id="main" class="app-pipco">
  <li id="main-20091123_0002">
    'RE'(action=read, p_action=read): 'wee'(action=read, p_action=read)
    <ul id="main-20091123_0002-files" class="app-attachment">
      <li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=read, p_action=read)</li>
    </ul>
<form id="form_main-20091123_0002-replies" method="post" enctype="multipart/form-data" action="/20091123_0002/replies/123.45/update.html">
<input name="_token" type="hidden" value="#{Runo.token}" />
    <ul id="main-20091123_0002-replies" class="app-pipco">
      <li id="main-20091123_0002-replies-20091125_0002"><a>'oops.'(action=update, p_action=update)</a></li>
    </ul>
[replies-update]
</form>
    'potato'
  </li>
</ul>
_html
      result,
      'Field#get should be able to handle a partial action'
    )
  end

  def test_get_partial_forbidden
    Runo.client = 'carl'
    assert_match(
      /\(action=update/,
      @sd.item('20091123_0001', 'files').get(:action => :update)
    )
    assert_match(
      /\(action=update/,
      @sd.item('20091123_0001', 'files', '20091123_0001').get(:action => :update)
    )

    @sd.instance_variable_set(:@item_object, {}) # remove item('_001')

    Runo.client = nil
    assert_raise(
      Runo::Error::Forbidden,
      'Field#get should not show an inner attachment when the parent is forbidden'
    ) {
      @sd.item('20091123_0001', 'files').get(:action => :update)
    }
    assert_raise(
      Runo::Error::Forbidden,
      'Field#get should not show an inner attachment when the parent is forbidden'
    ) {
      @sd.item('20091123_0001', 'files', '20091123_0001').get(:action => :update)
    }
  end

  def test_post_partial
    Runo.client = 'don'
    original_val = YAML.load @sd.val.to_yaml
    @sd.update(
      '20091123_0002' => {
        'replies' => {
          '_0001' => {'reply' => 'yum.'},
        },
      }
    )
    assert_equal(
      original_val,
      @sd.val,
      'Field#val should not change before the commit'
    )
    @sd.commit
    assert_not_equal(
      original_val,
      @sd.val,
      'Field#val should change after the commit'
    )
  end

  def test_post_attachment_forbidden
    Runo.client = nil
    assert_raise(
      Runo::Error::Forbidden,
      'Field#post to an inner attachment w/o the perm of the parent should be forbidden'
    ) {
      @sd.update(
        '20091123_0002' => {
          'files' => {
            '_0001' => {'file' => 'evil.jpg'},
          },
        }
      )
    }
    assert_raise(
      Runo::Error::Forbidden,
      'Field#post to an inner attachment w/o the perm of the parent should be forbidden'
    ) {
      @sd.update(
        '20091123_0002' => {
          'files'   => {
            '20091123_0001' => {'file' => 'evil.png'},
          }
        }
      )
    }
    assert_raise(
      Runo::Error::Forbidden,
      'Field#post to an inner attachment w/o the perm of the parent should be forbidden'
    ) {
      @sd.item('20091123_0002', 'files', '20091123_0001').update('file' => 'evil.gif')
    }
  end

  def test_commit_partial
    Runo.client = 'don'
    @sd.update(
      '20091123_0002' => {
        'replies' => {
          '_0001' => {'reply'  => 'yum.'},
        },
      }
    )
    orig_val = @sd.val('20091123_0002', 'replies').dup

    @sd.commit :temp
    new_val = @sd.val('20091123_0002', 'replies').dup
    assert_equal(
      orig_val.size + 1,
      new_val.size,
      'Field#val should change after the commit :temp'
    )

    new_id = new_val.keys.find {|id| new_val[id] == {'_owner' => 'don', 'reply'  => 'yum.'} }
    @sd.update(
      '20091123_0002' => {
        'replies' => {
          new_id => {
            :action => :delete,
            'reply' => 'yum.',
          },
        },
      }
    )

    @sd.commit :temp
    new_val = @sd.val('20091123_0002', 'replies').dup
    assert_equal(
      orig_val,
      new_val,
      'Field#val should change after the commit :temp'
    )
  end

  def test_post_mixed
    Runo.client = 'don'

    # create a sub-item on the pending item
    @sd.update(
      '_1234' => {
        '_owner'  => 'don',
        'replies' => {
          '_0001' => {
            '_owner' => 'don',
            'reply'  => 'yum.',
          },
        },
      }
    )
    orig_val = @sd.val('_1234', 'replies').dup
    assert_equal(
      {},
      orig_val,
      'Field#val should change after the commit :temp'
    )

    orig_storage = @sd.storage
    @sd.instance_variable_set(:@storage, nil) # pretend persistent
    @sd.commit :temp
    @sd.instance_variable_set(:@storage, orig_storage)

    new_val = @sd.val('_1234', 'replies').dup
    assert_equal(
      {'_owner' => 'don', 'reply'  => 'yum.'},
      new_val.values.first,
      'Field#val should change after the commit :temp'
    )

    # delete the sub-item
    new_id = new_val.keys.find {|id| new_val[id] == {'_owner' => 'don', 'reply'  => 'yum.'} }
    @sd.update(
      '_1234' => {
        'replies' => {
          new_id => {
            :action  => :delete,
            '_owner' => 'don',
            'reply'  => 'yum.',
          },
        },
      }
    )
    assert_equal(
      :delete,
      @sd.item('_1234', 'replies', new_id).action,
      'Set::Dynamic#post should not overwrite the action of descendant'
    )

    orig_storage = @sd.storage
    @sd.instance_variable_set(:@storage, nil) # pretend persistent
    @sd.commit :temp
    @sd.instance_variable_set(:@storage, orig_storage)

    new_val = @sd.val('_1234', 'replies').dup
    assert_equal(
      {},
      new_val,
      'Field#val should change after the commit :temp'
    )

    # create an another sub-item
    @sd.update(
      '_1234' => {
        '_owner'  => 'don',
        'replies' => {
          '_0001' => {
            '_owner' => 'don',
            'reply'  => 'yuck.',
          },
        },
      }
    )

    orig_storage = @sd.storage
    @sd.instance_variable_set(:@storage, nil) # pretend persistent
    @sd.commit :temp
    @sd.instance_variable_set(:@storage, orig_storage)

    new_val = @sd.val('_1234', 'replies').dup
    assert_equal(
      {'_owner' => 'don', 'reply'  => 'yuck.'},
      new_val.values.first,
      'Field#val should change after the commit :temp'
    )
  end

end
