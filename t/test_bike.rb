# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class TC_Bike < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_session
    assert(
      Bike.session.respond_to?(:[]),
      'Bike.session should be a Session or Hash'
    )
  end

  def test_client
    Bike.client = nil
    assert_equal(
      'nobody',
      Bike.client,
      'Bike.client should return nobody before login'
    )

    Bike.client = 'frank'
    assert_equal(
      'frank',
      Bike.client,
      'Bike.client should return the user who logged in'
    )

    Bike.client = nil
    assert_equal(
      'nobody',
      Bike.client,
      'Bike.client should return nobody after logout'
    )
  end

  def test_rebuild_params
    bike = Bike.new

    hash = bike.instance_eval {
      rebuild_params(
        '.action' => 'update'
      )
    }
    assert_equal(
      {:action => :update},
      hash,
      'Bike#rebuild_params should be able to rebuild special symbols'
    )

    hash = bike.instance_eval {
      rebuild_params(
        '.action-update' => 'submit'
      )
    }
    assert_equal(
      {:action => :update},
      hash,
      'Bike#rebuild_params should be able to rebuild special symbols'
    )

    hash = bike.instance_eval {
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
      'Bike#rebuild_params should rebuild both the special symbols and regular items'
    )

    hash = bike.instance_eval {
      rebuild_params(
        '_token'      => 'foo',
        'dest_action' => 'bar'
      )
    }
    assert_equal(
      {
        :token       => 'foo',
        :dest_action => 'bar',
      },
      hash,
      'Bike#rebuild_params should use symbols for special keys'
    )

    hash = bike.instance_eval {
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
      'Bike#rebuild_params should be able to rebuild any combination of symbols and items'
    )

    hash = bike.instance_eval {
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
      'Bike#rebuild_params should be able to rebuild any combination of symbols and items'
    )
  end

  def test_steps_of
    assert_equal(
      ['foo', 'bar'],
      Bike::Path.steps_of('/foo/bar/'),
      'Bike::Path.steps_of should be able to extract item steps from path_info'
    )
    assert_equal(
      ['foo', 'bar'],
      Bike::Path.steps_of('/foo/bar/create.html'),
      'Bike::Path.steps_of should ignore the pseudo-filename'
    )
    assert_equal(
      ['foo'],
      Bike::Path.steps_of('/foo/bar'),
      'Bike::Path.steps_of should ignore the last step without a following slash'
    )
    assert_equal(
      ['foo', 'bar'],
      Bike::Path.steps_of('/foo//bar/baz=123/'),
      'Bike::Path.steps_of should distinguish item steps from conds'
    )
    assert_equal(
      ['foo', 'bar'],
      Bike::Path.steps_of('/1234567890.123456/foo/bar/'),
      'Bike::Path.steps_of should distinguish item steps from a tid'
    )
  end

  def test_steps_of_with_empty_steps
    assert_equal(
      [],
      Bike::Path.steps_of(''),
      'Bike::Path.steps_of should return empty array when there is no item steps'
    )
    assert_equal(
      [],
      Bike::Path.steps_of('/'),
      'Bike::Path.steps_of should return empty array when there is no item steps'
    )
    assert_equal(
      [],
      Bike::Path.steps_of('/index.html'),
      'Bike::Path.steps_of should return empty array when there is no item steps'
    )
  end

  def test_steps_of_with_cond_d
    assert_equal(
      ['foo', 'bar'],
      Bike::Path.steps_of('/foo/bar/2009/'),
      'Bike::Path.steps_of should distinguish item steps from ambiguous conds[:d]'
    )
    assert_equal(
      ['foo', 'bar'],
      Bike::Path.steps_of('/foo/bar/1970/'),
      'Bike::Path.steps_of should distinguish item steps from ambiguous conds[:d]'
    )
    assert_equal(
      ['foo', 'bar', '3001'],
      Bike::Path.steps_of('/foo/bar/3001/'),
      'Bike::Path.steps_of should be patched in the next millennium :-)'
    )
  end

  def test_conds_of
    assert_equal(
      {},
      Bike::Path.conds_of('/foo/bar/'),
      'Bike::Path.conds_of should return empty hash when there is no conds'
    )
    assert_equal(
      {
        :baz => '123',
        :qux => '456',
      },
      Bike::Path.conds_of('/foo/bar/baz=123/qux=456/'),
      'Bike::Path.conds_of should be able to extract conds from path_info'
    )
    assert_equal(
      {
        :baz => '123',
        :qux => '456',
      },
      Bike::Path.conds_of('/foo/bar/baz=123/qux=456/create.html'),
      'Bike::Path.conds_of should ignore the pseudo-filename'
    )
    assert_equal(
      {
        :baz => '1234',
      },
      Bike::Path.conds_of('/foo/bar//baz=1234//qux=4567'),
      'Bike::Path.conds_of should ignore the item steps and the last step without a slash'
    )
  end

  def test_conds_of_with_empty_conds
    assert_equal(
      {},
      Bike::Path.conds_of(''),
      'Bike::Path.conds_of should return empty hash when there is no conds'
    )
    assert_equal(
      {},
      Bike::Path.conds_of('/'),
      'Bike::Path.conds_of should return empty hash when there is no conds'
    )
    assert_equal(
      {},
      Bike::Path.conds_of('/index.html'),
      'Bike::Path.conds_of should return empty hash when there is no conds'
    )
  end

  def test_conds_of_with_cond_d
    assert_equal(
      {
        :d   => '200911',
        :baz => '1234',
        :qux => '4567',
      },
      Bike::Path.conds_of('/foo/bar/200911/baz=1234/qux=4567/'),
      'Bike::Path.conds_of should be able to distinguish ambiguous conds[:d]'
    )
    assert_equal(
      {
        :baz => '1234',
        :qux => '4567',
      },
      Bike::Path.conds_of('/foo/bar/20091129_0001/baz=1234/qux=4567/'),
      'Bike::Path.conds_of should ignore the full-formatted id'
    )
  end

  def test_conds_of_with_cond_id
    assert_equal(
      ['foo', 'bar'],
      Bike::Path.steps_of('/foo/bar/20091205/9/baz=1234/qux=4567/'),
      'Bike::Path.steps_of should ignore conds[:id]'
    )
    assert_equal(
      {
        :id  => '20091205_0009',
        :baz => '1234',
        :qux => '4567',
      },
      Bike::Path.conds_of('/foo/bar/20091205/9/baz=1234/qux=4567/'),
      'Bike::Path.conds_of should extract conds[:id] from the path sequence'
    )
  end

  def test_action_of
    assert_equal(
      :create,
      Bike::Path.action_of('/foo/bar/create.html'),
      'Bike::Path.action_of should extract the action from path_info'
    )

    assert_nil(
      Bike::Path.action_of('/foo/bar/index.html'),
      'Bike::Path.action_of should return nil if the pseudo-filename is index.*'
    )
    assert_nil(
      Bike::Path.action_of('/foo/bar/'),
      'Bike::Path.action_of should return nil if no pseudo-filename is given'
    )
    assert_nil(
      Bike::Path.action_of('/foo/bar/_detail.html'),
      "Bike::Path.action_of should return nil if the pseudo-filename begins with '_'"
    )
  end

  def test_sub_action_of
    assert_equal(
      :detail,
      Bike::Path.sub_action_of('/foo/bar/read_detail.html'),
      'Bike::Path.sub_action_of should extract the sub_action from path_info'
    )
    assert_nil(
      Bike::Path.sub_action_of('/foo/bar/read.html'),
      "Bike::Path.sub_action_of should return nil if the pseudo-filename does not include '_'"
    )
  end

  def test_base_of
    sd = Bike::Path.base_of '/foo/bar/main/index.html'
    assert_instance_of(
      Bike::Set::Dynamic,
      sd,
      'Bike::Path.base_of should return a set_dynamic'
    )
    assert_equal(
      '-foo-bar-main',
      sd[:full_name],
      'Bike::Path.base_of should return a set_dynamic at the bottom of the given steps'
    )

    sd = Bike::Path.base_of '/foo/bar/index.html'
    assert_instance_of(
      Bike::Set::Dynamic,
      sd,
      'Bike::Path.base_of should return a set_dynamic'
    )
    assert_equal(
      '-foo-bar-main',
      sd[:full_name],
      "Bike::Path.base_of should return the item('main') if the given steps point at a folder"
    )

    sd = Bike::Path.base_of '/foo/qux/index.html'
    assert_instance_of(
      Bike::Set::Dynamic,
      sd,
      "Bike::Path.base_of should return an available set_dynamic if there is no 'main' in the folder"
    )
    assert_equal(
      '-foo-qux-abc',
      sd[:full_name],
      "Bike::Path.base_of should return the first set_dynamic if there is no 'main' in the folder"
    )

    sd = Bike::Path.base_of '/foo/bar/20091120_0001/comment/index.html'
    assert_instance_of(
      Bike::Text,
      sd,
      'Bike::Path.base_of should return a text if designated'
    )

    sd = Bike::Path.base_of '/foo/bar/20091120_0001/files/index.html'
    assert_instance_of(
      Bike::Set::Dynamic,
      sd,
      'Bike::Path.base_of should return a set_dynamic'
    )
    assert_equal(
      '-foo-bar-main-20091120_0001-files',
      sd[:full_name],
      "Bike::Path.base_of should be able to dive into any depth from the folder"
    )

    sd = Bike::Path.base_of '/foo/bar/20091120_0002/files/index.html'
    assert_nil(
      sd,
      'Bike::Path.base_of should return nil if there is no set_dynamic at the steps'
    )
  end

  def test_base_of_empty_folder
    f = Bike::Path.base_of '/foo/qux/moo/index.html'
    assert_instance_of(
      Bike::Set::Static::Folder,
      f,
      'Bike::Path.base_of should return an folder if there is no SD in it'
    )
    assert_equal(
      '-foo-qux-moo',
      f[:full_name],
      'Bike::Path.base_of should return an folder if there is no SD in it'
    )
  end

  def test_path_of
    assert_equal(
      '20091224/123/',
      Bike::Path.path_of(:id => '20091224_0123'),
      'Bike::Path.path_of should return a special combination of pseudo-steps for conds[:id]'
    )
    assert_equal(
      '20091224/123/',
      Bike::Path.path_of(:d => '2009', :id => '20091224_0123'),
      'Bike::Path.path_of should ignore the other conds if there is conds[:id]'
    )

    assert_equal(
      '20091224/123/',
      Bike::Path.path_of(:id => ['20091224_0123']),
      'Bike::Path.path_of should return a special combination of pseudo-steps for conds[:id]'
    )
    assert_equal(
      'id=20091224_0123,20100222_1234/',
      Bike::Path.path_of(:id => ['20091224_0123', '20100222_1234']),
      'Bike::Path.path_of should return multiple ids as a comma-separated form'
    )
    assert_equal(
      '',
      Bike::Path.path_of(:id => []),
      'Bike::Path.path_of should return an empty string when given an empty conds[:id]'
    )

    assert_equal(
      'id=carl/',
      Bike::Path.path_of(:id => '00000000_carl'),
      "Bike::Path.path_of should use '/id=xxx/' form for a short id"
    )
    assert_equal(
      'id=20091224_0123,carl/',
      Bike::Path.path_of(:id => ['20091224_0123', '00000000_carl']),
      "Bike::Path.path_of should use short ids in a comma-separated form"
    )

    assert_equal(
      'foo=bar/',
      Bike::Path.path_of(:foo => 'bar'),
      'Bike::Path.path_of should return a path of which steps represent the conds'
    )
    assert_equal(
      'foo=bar/p=123/',
      Bike::Path.path_of(:p => 123, :foo => 'bar'),
      'Bike::Path.path_of should return the step for conds[:p] at the tail end'
    )
    assert_equal(
      'foo=bar/order=desc/p=123/',
      Bike::Path.path_of(:p => 123, :order =>'desc', :foo => 'bar'),
      'Bike::Path.path_of should return the step for conds[:order] at the tail end'
    )

    assert_equal(
      'foo=bar/',
      Bike::Path.path_of(:p => 1, :foo => 'bar'),
      'Bike::Path.path_of should omit the step for conds[:p] when conds[:p] == 1'
    )
    assert_equal(
      'p=1/',
      Bike::Path.path_of(:p => 1),
      'Bike::Path.path_of should not omit the step for conds[:p] when there is no other conds'
    )

    assert_equal(
      'foo=1,2,3/',
      Bike::Path.path_of(:foo => [1, 2, 3]),
      'Bike::Path.path_of should return multiple values as a comma-separated form'
    )
  end

  def test_params_from_request
    bike = Bike.new

    env = Rack::MockRequest.env_for(
      'http://example.com/foo/bar/main/qux=456/read_detail.html?acorn=round',
      {
        :method      => 'post',
        :script_name => '',
        :input       => 'coax=true&some-doors=open',
      }
    )
    req = Rack::Request.new env
    params = bike.instance_eval {
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
      'Bike#params_from_request should build params from req.path_info and req.params'
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
    params = bike.instance_eval {
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
      'Bike#params_from_request should build params from req.path_info and req.params'
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
    params = bike.instance_eval {
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
      'Bike#params_from_request should attach the params from path_info to the base SD'
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
    params = bike.instance_eval {
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
      'Bike#params_from_request should build params from req.path_info and req.params'
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
    params = bike.instance_eval {
      params_from_request req
    }
    assert_equal(
      {
        :conds      => {},
        :action     => :open,
        :sub_action => :sesami,
      },
      params,
      'Bike#params_from_request should override path_info by :input'
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
    params = bike.instance_eval {
      params_from_request req
    }
    assert_equal(
      {
        :conds      => {},
        :action     => :open,
        :sub_action => :sesami,
      },
      params,
      'Bike#params_from_request should override path_info by :input'
    )
  end

  def test_current
    Bike.current[:foo] = 'main foo'
    main_current = Bike.current

    t = Thread.new {
      assert_not_equal(
        main_current,
        Bike.current,
        'Bike.current should be unique per a thread'
      )
      assert_not_equal(
        'main foo',
        Bike.current[:foo],
        'Bike.current should be unique per a thread'
      )
      Bike.current[:foo] = 'child foo'
    }
    t.join

    assert_equal(
      'main foo',
      Bike.current[:foo],
      'Bike.current should be unique per a thread'
    )
  end

  def test_libdir
    assert_match(
      %r{^.*/lib$},
      Bike.libdir,
      'Bike#libdir should return the lib/ directory where the bike.rb is in'
    )
  end

end
