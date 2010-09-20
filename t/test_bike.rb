# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class TC_Runo < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_session
    assert(
      Runo.session.respond_to?(:[]),
      'Runo.session should be a Session or Hash'
    )
  end

  def test_client
    Runo.client = nil
    assert_equal(
      'nobody',
      Runo.client,
      'Runo.client should return nobody before login'
    )

    Runo.client = 'frank'
    assert_equal(
      'frank',
      Runo.client,
      'Runo.client should return the user who logged in'
    )

    Runo.client = nil
    assert_equal(
      'nobody',
      Runo.client,
      'Runo.client should return nobody after logout'
    )
  end

  def test_rebuild_params
    runo = Runo.new

    hash = runo.instance_eval {
      rebuild_params(
        '.action' => 'update'
      )
    }
    assert_equal(
      {:action => :update},
      hash,
      'Runo#rebuild_params should be able to rebuild special symbols'
    )

    hash = runo.instance_eval {
      rebuild_params(
        '.action-update' => 'submit'
      )
    }
    assert_equal(
      {:action => :update},
      hash,
      'Runo#rebuild_params should be able to rebuild special symbols'
    )

    hash = runo.instance_eval {
      rebuild_params(
        'noo'               => 'what?',
        'noo.action-update' => 'submit',
        'noo.conds-id'      => '4567'
      )
    }
    assert_equal(
      {
        'noo' => {
          :self   => 'what?',
          :action => :update,
          :conds  => {:id => '4567'},
        },
      },
      hash,
      'Runo#rebuild_params should rebuild both the special symbols and regular items'
    )

    hash = runo.instance_eval {
      rebuild_params(
        'moo.conds-p'                   => '9',
        'moo-4567-addr.conds-zip-upper' => '110'
      )
    }
    assert_equal(
      {
        'moo' => {
          :conds => {:p => '9'},
          '4567' => {
            'addr' => {
              :conds => {:'zip-upper' => '110'},
            },
          },
        },
      },
      hash,
      'Runo#rebuild_params should be able to rebuild any combination of symbols and items'
    )

    hash = runo.instance_eval {
      rebuild_params(
        'foo-bar.conds-id'  => '1234',
        'foo-bar.conds-p'   => ['42'],
        'foo-bar.action'    => 'update',
        'foo-baz'           => ['boo', 'bee'],
        'foo'               => 'oops',
        'qux.action-create' => 'submit',
        'qux.status-public' => 'oops'
      )
    }
    assert_equal(
      {
        'foo' => {
          :self => 'oops',
          'bar' => {
            :action => :update,
            :conds  => {
              :id => '1234',
              :p  => ['42'],
            },
          },
          'baz' => ['boo', 'bee'],
        },
        'qux' => {
          :action => :create,
          :status => :public,
        },
      },
      hash,
      'Runo#rebuild_params should be able to rebuild any combination of symbols and items'
    )
  end

  def test_steps_of
    assert_equal(
      ['foo', 'bar'],
      Runo::Path.steps_of('/foo/bar/'),
      'Runo::Path.steps_of should be able to extract item steps from path_info'
    )
    assert_equal(
      ['foo', 'bar'],
      Runo::Path.steps_of('/foo/bar/create.html'),
      'Runo::Path.steps_of should ignore the pseudo-filename'
    )
    assert_equal(
      ['foo'],
      Runo::Path.steps_of('/foo/bar'),
      'Runo::Path.steps_of should ignore the last step without a following slash'
    )
    assert_equal(
      ['foo', 'bar'],
      Runo::Path.steps_of('/foo//bar/baz=123/'),
      'Runo::Path.steps_of should distinguish item steps from conds'
    )
    assert_equal(
      ['foo', 'bar'],
      Runo::Path.steps_of('/1234567890.123456/foo/bar/'),
      'Runo::Path.steps_of should distinguish item steps from a tid'
    )
  end

  def test_steps_of_with_empty_steps
    assert_equal(
      [],
      Runo::Path.steps_of(''),
      'Runo::Path.steps_of should return empty array when there is no item steps'
    )
    assert_equal(
      [],
      Runo::Path.steps_of('/'),
      'Runo::Path.steps_of should return empty array when there is no item steps'
    )
    assert_equal(
      [],
      Runo::Path.steps_of('/index.html'),
      'Runo::Path.steps_of should return empty array when there is no item steps'
    )
  end

  def test_steps_of_with_cond_d
    assert_equal(
      ['foo', 'bar'],
      Runo::Path.steps_of('/foo/bar/2009/'),
      'Runo::Path.steps_of should distinguish item steps from ambiguous conds[:d]'
    )
    assert_equal(
      ['foo', 'bar'],
      Runo::Path.steps_of('/foo/bar/1970/'),
      'Runo::Path.steps_of should distinguish item steps from ambiguous conds[:d]'
    )
    assert_equal(
      ['foo', 'bar', '3001'],
      Runo::Path.steps_of('/foo/bar/3001/'),
      'Runo::Path.steps_of should be patched in the next millennium :-)'
    )
  end

  def test_conds_of
    assert_equal(
      {},
      Runo::Path.conds_of('/foo/bar/'),
      'Runo::Path.conds_of should return empty hash when there is no conds'
    )
    assert_equal(
      {
        :baz => '123',
        :qux => '456',
      },
      Runo::Path.conds_of('/foo/bar/baz=123/qux=456/'),
      'Runo::Path.conds_of should be able to extract conds from path_info'
    )
    assert_equal(
      {
        :baz => '123',
        :qux => '456',
      },
      Runo::Path.conds_of('/foo/bar/baz=123/qux=456/create.html'),
      'Runo::Path.conds_of should ignore the pseudo-filename'
    )
    assert_equal(
      {
        :baz => '1234',
      },
      Runo::Path.conds_of('/foo/bar//baz=1234//qux=4567'),
      'Runo::Path.conds_of should ignore the item steps and the last step without a slash'
    )
  end

  def test_conds_of_with_empty_conds
    assert_equal(
      {},
      Runo::Path.conds_of(''),
      'Runo::Path.conds_of should return empty hash when there is no conds'
    )
    assert_equal(
      {},
      Runo::Path.conds_of('/'),
      'Runo::Path.conds_of should return empty hash when there is no conds'
    )
    assert_equal(
      {},
      Runo::Path.conds_of('/index.html'),
      'Runo::Path.conds_of should return empty hash when there is no conds'
    )
  end

  def test_conds_of_with_cond_d
    assert_equal(
      {
        :d   => '200911',
        :baz => '1234',
        :qux => '4567',
      },
      Runo::Path.conds_of('/foo/bar/200911/baz=1234/qux=4567/'),
      'Runo::Path.conds_of should be able to distinguish ambiguous conds[:d]'
    )
    assert_equal(
      {
        :baz => '1234',
        :qux => '4567',
      },
      Runo::Path.conds_of('/foo/bar/20091129_0001/baz=1234/qux=4567/'),
      'Runo::Path.conds_of should ignore the full-formatted id'
    )
  end

  def test_conds_of_with_cond_id
    assert_equal(
      ['foo', 'bar'],
      Runo::Path.steps_of('/foo/bar/20091205/9/baz=1234/qux=4567/'),
      'Runo::Path.steps_of should ignore conds[:id]'
    )
    assert_equal(
      {
        :id  => '20091205_0009',
        :baz => '1234',
        :qux => '4567',
      },
      Runo::Path.conds_of('/foo/bar/20091205/9/baz=1234/qux=4567/'),
      'Runo::Path.conds_of should extract conds[:id] from the path sequence'
    )
  end

  def test_action_of
    assert_equal(
      :create,
      Runo::Path.action_of('/foo/bar/create.html'),
      'Runo::Path.action_of should extract the action from path_info'
    )

    assert_nil(
      Runo::Path.action_of('/foo/bar/index.html'),
      'Runo::Path.action_of should return nil if the pseudo-filename is index.*'
    )
    assert_nil(
      Runo::Path.action_of('/foo/bar/'),
      'Runo::Path.action_of should return nil if no pseudo-filename is given'
    )
    assert_nil(
      Runo::Path.action_of('/foo/bar/_detail.html'),
      "Runo::Path.action_of should return nil if the pseudo-filename begins with '_'"
    )
  end

  def test_sub_action_of
    assert_equal(
      :detail,
      Runo::Path.sub_action_of('/foo/bar/read_detail.html'),
      'Runo::Path.sub_action_of should extract the sub_action from path_info'
    )
    assert_nil(
      Runo::Path.sub_action_of('/foo/bar/read.html'),
      "Runo::Path.sub_action_of should return nil if the pseudo-filename does not include '_'"
    )
  end

  def test_base_of
    sd = Runo::Path.base_of '/foo/bar/main/index.html'
    assert_instance_of(
      Runo::Set::Dynamic,
      sd,
      'Runo::Path.base_of should return a set_dynamic'
    )
    assert_equal(
      '-foo-bar-main',
      sd[:full_name],
      'Runo::Path.base_of should return a set_dynamic at the bottom of the given steps'
    )

    sd = Runo::Path.base_of '/foo/bar/index.html'
    assert_instance_of(
      Runo::Set::Dynamic,
      sd,
      'Runo::Path.base_of should return a set_dynamic'
    )
    assert_equal(
      '-foo-bar-main',
      sd[:full_name],
      "Runo::Path.base_of should return the item('main') if the given steps point at a folder"
    )

    sd = Runo::Path.base_of '/foo/qux/index.html'
    assert_instance_of(
      Runo::Set::Dynamic,
      sd,
      "Runo::Path.base_of should return an available set_dynamic if there is no 'main' in the folder"
    )
    assert_equal(
      '-foo-qux-abc',
      sd[:full_name],
      "Runo::Path.base_of should return the first set_dynamic if there is no 'main' in the folder"
    )

    sd = Runo::Path.base_of '/foo/bar/20091120_0001/comment/index.html'
    assert_instance_of(
      Runo::Text,
      sd,
      'Runo::Path.base_of should return a text if designated'
    )

    sd = Runo::Path.base_of '/foo/bar/20091120_0001/files/index.html'
    assert_instance_of(
      Runo::Set::Dynamic,
      sd,
      'Runo::Path.base_of should return a set_dynamic'
    )
    assert_equal(
      '-foo-bar-main-20091120_0001-files',
      sd[:full_name],
      "Runo::Path.base_of should be able to dive into any depth from the folder"
    )

    sd = Runo::Path.base_of '/foo/bar/20091120_0002/files/index.html'
    assert_nil(
      sd,
      'Runo::Path.base_of should return nil if there is no set_dynamic at the steps'
    )
  end

  def test_base_of_empty_folder
    f = Runo::Path.base_of '/foo/qux/moo/index.html'
    assert_instance_of(
      Runo::Set::Static::Folder,
      f,
      'Runo::Path.base_of should return an folder if there is no SD in it'
    )
    assert_equal(
      '-foo-qux-moo',
      f[:full_name],
      'Runo::Path.base_of should return an folder if there is no SD in it'
    )
  end

  def test_path_of
    assert_equal(
      '20091224/123/',
      Runo::Path.path_of(:id => '20091224_0123'),
      'Runo::Path.path_of should return a special combination of pseudo-steps for conds[:id]'
    )
    assert_equal(
      '20091224/123/',
      Runo::Path.path_of(:d => '2009', :id => '20091224_0123'),
      'Runo::Path.path_of should ignore the other conds if there is conds[:id]'
    )

    assert_equal(
      '20091224/123/',
      Runo::Path.path_of(:id => ['20091224_0123']),
      'Runo::Path.path_of should return a special combination of pseudo-steps for conds[:id]'
    )
    assert_equal(
      'id=20091224_0123,20100222_1234/',
      Runo::Path.path_of(:id => ['20091224_0123', '20100222_1234']),
      'Runo::Path.path_of should return multiple ids as a comma-separated form'
    )
    assert_equal(
      '',
      Runo::Path.path_of(:id => []),
      'Runo::Path.path_of should return an empty string when given an empty conds[:id]'
    )

    assert_equal(
      'id=carl/',
      Runo::Path.path_of(:id => '00000000_carl'),
      "Runo::Path.path_of should use '/id=xxx/' form for a short id"
    )
    assert_equal(
      'id=20091224_0123,carl/',
      Runo::Path.path_of(:id => ['20091224_0123', '00000000_carl']),
      "Runo::Path.path_of should use short ids in a comma-separated form"
    )

    assert_equal(
      'foo=bar/',
      Runo::Path.path_of(:foo => 'bar'),
      'Runo::Path.path_of should return a path of which steps represent the conds'
    )
    assert_equal(
      'foo=bar/p=123/',
      Runo::Path.path_of(:p => 123, :foo => 'bar'),
      'Runo::Path.path_of should return the step for conds[:p] at the tail end'
    )
    assert_equal(
      'foo=bar/order=desc/p=123/',
      Runo::Path.path_of(:p => 123, :order =>'desc', :foo => 'bar'),
      'Runo::Path.path_of should return the step for conds[:order] at the tail end'
    )

    assert_equal(
      'foo=bar/',
      Runo::Path.path_of(:p => 1, :foo => 'bar'),
      'Runo::Path.path_of should omit the step for conds[:p] when conds[:p] == 1'
    )
    assert_equal(
      'p=1/',
      Runo::Path.path_of(:p => 1),
      'Runo::Path.path_of should not omit the step for conds[:p] when there is no other conds'
    )

    assert_equal(
      'foo=1,2,3/',
      Runo::Path.path_of(:foo => [1, 2, 3]),
      'Runo::Path.path_of should return multiple values as a comma-separated form'
    )
  end

  def test_params_from_request
    runo = Runo.new

    env = Rack::MockRequest.env_for(
      'http://example.com/foo/bar/main/qux=456/read_detail.html?acorn=round',
      {
        :method      => 'post',
        :script_name => '',
        :input       => 'coax=true&some-doors=open',
      }
    )
    req = Rack::Request.new env
    params = runo.instance_eval {
      params_from_request req
    }
    assert_equal(
      {
        :conds      => {:qux => '456'},
        :action     => :read,
        :sub_action => :detail,
        'acorn'     => 'round',
        'coax'      => 'true',
        'some'      => {'doors' => 'open'},
      },
      params,
      'Runo#params_from_request should build params from req.path_info and req.params'
    )

    env = Rack::MockRequest.env_for(
      'http://example.com/foo/bar/qux=456/index.html?acorn=round',
      {
        :method      => 'post',
        :script_name => '',
        :input       => 'coax=true&some-doors=open',
      }
    )
    req = Rack::Request.new env
    params = runo.instance_eval {
      params_from_request req
    }
    assert_equal(
      {
        :conds      => {:qux => '456'},
        :action     => nil,
        :sub_action => nil,
        'acorn'     => 'round',
        'coax'      => 'true',
        'some'      => {'doors' => 'open'},
      },
      params,
      'Runo#params_from_request should build params from req.path_info and req.params'
    )

    env = Rack::MockRequest.env_for(
      'http://example.com/foo/bar/20091120_0001/files/qux=456/index.html?acorn=round',
      {
        :method      => 'post',
        :script_name => '',
        :input       => 'coax=true&some-doors=open',
      }
    )
    req = Rack::Request.new env
    params = runo.instance_eval {
      params_from_request req
    }
    assert_equal(
      {
        :conds      => {:qux => '456'},
        :action     => nil,
        :sub_action => nil,
        'acorn'     => 'round',
        'coax'      => 'true',
        'some'      => {'doors' => 'open'},
      },
      params,
      'Runo#params_from_request should attach the params from path_info to the base SD'
    )

    env = Rack::MockRequest.env_for(
      'http://example.com/foo/bar/qux=456/index.html?acorn=round',
      {
        :method      => 'post',
        :script_name => '',
        :input       => 'some-doors=open&some.action-open=submit',
      }
    )
    req = Rack::Request.new env
    params = runo.instance_eval {
      params_from_request req
    }
    assert_equal(
      {
        :conds      => {:qux => '456'},
        :action     => nil,
        :sub_action => nil,
        'acorn'     => 'round',
        'some'      => {'doors' => 'open', :action => :open},
      },
      params,
      'Runo#params_from_request should build params from req.path_info and req.params'
    )

    env = Rack::MockRequest.env_for(
      'http://example.com/foo/bar/update.html',
      {
        :method      => 'post',
        :script_name => '',
        :input       => '.action=open_sesami',
      }
    )
    req = Rack::Request.new env
    params = runo.instance_eval {
      params_from_request req
    }
    assert_equal(
      {
        :conds      => {},
        :action     => :open,
        :sub_action => :sesami,
      },
      params,
      'Runo#params_from_request should override path_info by :input'
    )

    env = Rack::MockRequest.env_for(
      'http://example.com/foo/bar/update.html',
      {
        :method      => 'post',
        :script_name => '',
        :input       => '.action-open_sesami=submit',
      }
    )
    req = Rack::Request.new env
    params = runo.instance_eval {
      params_from_request req
    }
    assert_equal(
      {
        :conds      => {},
        :action     => :open,
        :sub_action => :sesami,
      },
      params,
      'Runo#params_from_request should override path_info by :input'
    )
  end

  def test_current
    Runo.current[:foo] = 'main foo'
    main_current = Runo.current

    t = Thread.new {
      assert_not_equal(
        main_current,
        Runo.current,
        'Runo.current should be unique per a thread'
      )
      assert_not_equal(
        'main foo',
        Runo.current[:foo],
        'Runo.current should be unique per a thread'
      )
      Runo.current[:foo] = 'child foo'
    }
    t.join

    assert_equal(
      'main foo',
      Runo.current[:foo],
      'Runo.current should be unique per a thread'
    )
  end

  def test_login
    Runo.client = nil
    res = Runo.new.send(
      :login,
      Runo::Set::Static::Folder.root.item('foo', 'main'),
      {'id' => 'test', 'pw' => 'test', :conds => {:id => '20100222_0123'}, 'dest_action' => 'update'}
    )
    assert_equal(
      'test',
      Runo.client,
      'Runo#login should set Runo.client given a valid pair of user/password'
    )
    assert_match(
      %r{/foo/20100222/123/update.html},
      res[1]['Location'],
      'Runo#login should return a proper location header'
    )
  end

  def test_login_default_action
    Runo.client = nil
    res = Runo.new.send(
      :login,
      Runo::Set::Static::Folder.root.item('foo', 'main'),
      {'id' => 'test', 'pw' => 'test', :conds => {:id => '20100222_0123'}}
    )
    assert_match(
      %r{/foo/20100222/123/index.html},
      res[1]['Location'],
      "Runo#login should set 'index' as the default action of a location"
    )
  end

  def test_login_with_wrong_account
    Runo.client = nil

    assert_raise(
      Runo::Error::Forbidden,
      'Runo#login should raise Error::Forbidden given a non-existent user'
    ) {
      Runo.new.send(
        :login,
        Runo::Set::Static::Folder.root.item('foo', 'main'),
        {'id' => 'non-existent', 'pw' => 'test'}
      )
    }
    assert_equal(
      'nobody',
      Runo.client,
      'Runo#login should not set Runo.client with a non-existent user'
    )

    assert_raise(
      Runo::Error::Forbidden,
      'Runo#login should raise Error::Forbidden given a empty password'
    ) {
      Runo.new.send(
        :login,
        Runo::Set::Static::Folder.root.item('foo', 'main'),
        {'id' => 'test', 'pw' => nil}
      )
    }
    assert_equal(
      'nobody',
      Runo.client,
      'Runo#login should not set Runo.client with an empty password'
    )

    assert_raise(
      Runo::Error::Forbidden,
      'Runo#login should raise Error::Forbidden given a wrong password'
    ) {
      res = Runo.new.send(
        :login,
        Runo::Set::Static::Folder.root.item('foo', 'main'),
        {
          'id' => 'test',
          'pw' => 'wrong',
          :conds => {:id => '20100222_0123'},
          'dest_action' => 'update'
        }
      )
    }
    assert_equal(
      'nobody',
      Runo.client,
      'Runo#login should not set Runo.client with a wrong password'
    )
  end

  def test_logout
    Runo.client = 'frank'
    res = Runo.new.send(
      :logout,
      Runo::Set::Static::Folder.root.item('foo', 'main'),
      {'id' => 'test', 'pw' => 'test', :conds => {:id => '20100222_0123'}}
    )
    assert_equal(
      'nobody',
      Runo.client,
      'Runo#logout should clear Runo.client'
    )
    assert_match(
      %r{/foo/20100222/123/index.html},
      res[1]['Location'],
      'Runo#logout should return a proper location header'
    )
  end

  def test_libdir
    assert_match(
      %r{^.*/lib$},
      Runo.libdir,
      'Runo#libdir should return the lib/ directory where the runo.rb is in'
    )
  end

end
