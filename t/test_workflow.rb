# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class TC_Workflow < Test::Unit::TestCase

  class Bike::Workflow::Foo < Bike::Workflow
    PERM = {
      :create => 0b11000,
      :read   => 0b11110,
      :update => 0b10100,
      :delete => 0b11000,
    }
  end

  def setup
  end

  def teardown
  end

  def test_instance
    sd = Bike::Set::Dynamic.new
    assert_instance_of(
      Bike::Workflow,
      Bike::Workflow.instance(sd),
      'Bike::Workflow.instance should return a Workflow instance if sd[:workflow] is nil'
    )
    sd = Bike::Set::Static::Folder.root.item('foo', 'main')
    assert_instance_of(
      Bike::Workflow::Blog,
      Bike::Workflow.instance(sd),
      'Bike::Workflow.instance should return a instance according to sd[:workflow]'
    )

    assert_equal(
      sd,
      Bike::Workflow.instance(sd).f,
      'Bike::Workflow.instance should set @f'
    )
  end

  def test_roles
    assert_equal(
      %w(none),
      Bike::Workflow.roles(0b00001),
      'Bike::Workflow.roles should return a human-readable string of the given roles'
    )
    assert_equal(
      %w(owner),
      Bike::Workflow.roles(0b00100),
      'Bike::Workflow.roles should return a human-readable string of the given roles'
    )
    assert_equal(
      %w(admin),
      Bike::Workflow.roles(0b10000),
      'Bike::Workflow.roles should return a human-readable string of the given roles'
    )
    assert_equal(
      %w(admin owner user),
      Bike::Workflow.roles(0b10110),
      'Bike::Workflow.roles should return a human-readable string of the given roles'
    )
  end

  def test_wf_permit_guest?
    wf = Bike::Workflow::Foo.new(nil)
    assert(
      !wf.send(:'permit?', Bike::Workflow::ROLE_USER, :create),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Bike::Workflow::ROLE_USER, :read),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      !wf.send(:'permit?', Bike::Workflow::ROLE_USER, :update),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      !wf.send(:'permit?', Bike::Workflow::ROLE_USER, :delete),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
  end

  def test_wf_permit_owner?
    wf = Bike::Workflow::Foo.new(nil)
    assert(
      !wf.send(:'permit?', Bike::Workflow::ROLE_OWNER, :create),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Bike::Workflow::ROLE_OWNER, :read),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Bike::Workflow::ROLE_OWNER, :update),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      !wf.send(:'permit?', Bike::Workflow::ROLE_OWNER, :delete),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
  end

  def test_wf_permit_group?
    wf = Bike::Workflow::Foo.new(nil)
    assert(
      wf.send(:'permit?', Bike::Workflow::ROLE_GROUP, :create),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Bike::Workflow::ROLE_GROUP, :read),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      !wf.send(:'permit?', Bike::Workflow::ROLE_GROUP, :update),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Bike::Workflow::ROLE_GROUP, :delete),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
  end

  def test_wf_permit_admin?
    wf = Bike::Workflow::Foo.new(nil)
    assert(
      wf.send(:'permit?', Bike::Workflow::ROLE_ADMIN, :create),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Bike::Workflow::ROLE_ADMIN, :read),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Bike::Workflow::ROLE_ADMIN, :update),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Bike::Workflow::ROLE_ADMIN, :delete),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
  end

  def test_wf_permit_login_action?
    wf = Bike::Workflow::Foo.new(nil)
    assert(
      wf.send(:'permit?', Bike::Workflow::ROLE_USER, :login),
      'Set::Workflow#permit? should always permit :login'
    )
    assert(
      wf.send(:'permit?', Bike::Workflow::ROLE_OWNER, :login),
      'Set::Workflow#permit? should always permit :login'
    )
    assert(
      wf.send(:'permit?', Bike::Workflow::ROLE_GROUP, :login),
      'Set::Workflow#permit? should always permit :login'
    )
    assert(
      wf.send(:'permit?', Bike::Workflow::ROLE_ADMIN, :login),
      'Set::Workflow#permit? should always permit :login'
    )
  end

  def test_wf_permit_abnormal_action?
    wf = Bike::Workflow::Foo.new(nil)
    assert(
      !wf.send(:'permit?', Bike::Workflow::ROLE_ADMIN, :'non-exist'),
      'Set::Workflow#permit? should always return false for non-exist actions'
    )
  end

  def test_permit_nobody?
    sd = Bike::Set::Static::Folder.root.item('foo', 'bar', 'main')
    Bike.client = nil
    assert(
      !sd.permit?(:create),
      "'nobody' should not create"
    )
    assert(
      sd.item('20091120_0001').permit?(:read),
      "'nobody' should be able to read the item"
    )
    assert(
      !sd.item('20091120_0001').permit?(:update),
      "'nobody' should not update carl's item"
    )
    assert(
      !sd.item('20091120_0001').permit?(:delete),
      "'nobody' should not delete carl's item"
    )
  end

  def test_permit_don?
    sd = Bike::Set::Static::Folder.root.item('foo', 'bar', 'main')
    Bike.client = 'don' # don belongs to the group of foo/bar/
    assert(
      sd.permit?(:create),
      'don should be able to create'
    )
    assert(
      sd.item('20091120_0001').permit?(:read),
      'don should be able to read the item'
    )
    assert(
      !sd.item('20091120_0001').permit?(:update),
      "don should not update carl's item"
    )
    assert(
      !sd.item('20091120_0001').permit?(:delete),
      "don should not delete carl's item"
    )
  end

  def test_permit_carl?
    sd = Bike::Set::Static::Folder.root.item('foo', 'bar', 'main')
    Bike.client = 'carl' # carl belongs to the group of foo/bar/, and the owner of the item #0001
    assert(
      sd.permit?(:create),
      'carl should be able to create'
    )
    assert(
      sd.item('20091120_0001').permit?(:read),
      'carl should be able to read the item'
    )
    assert(
      sd.item('20091120_0001').permit?(:update),
      "carl should be able to update his own item"
    )
    assert(
      sd.item('20091120_0001').permit?(:delete),
      "carl should be able to delete his own item"
    )
  end

  def test_permit_frank?
    sd = Bike::Set::Static::Folder.root.item('foo', 'bar', 'main')
    Bike.client = 'frank' # frank is an admin of foo/bar/
    assert(
      sd.permit?(:create),
      'frank should be able to create'
    )
    assert(
      sd.item('20091120_0001').permit?(:read),
      'frank should be able to read the item'
    )
    assert(
      sd.item('20091120_0001').permit?(:update),
      "frank should be able to update his own item"
    )
    assert(
      sd.item('20091120_0001').permit?(:delete),
      "frank should be able to delete his own item"
    )
  end

  def test_permit_abnormal_action?
    sd = Bike::Set::Static::Folder.root.item('foo', 'bar', 'main')
    Bike.client = 'frank'
    assert(
      !sd.permit?(:'****'),
      'frank should not **** on the stage'
    )
  end

  class Bike::Workflow::Test_default_action < Bike::Workflow
    DEFAULT_SUB_ITEMS = {
      '_owner' => {:klass => 'meta-owner'},
      '_group' => {:klass => 'meta-group'},
    }
    PERM = {
      :create => 0b11000,
      :read   => 0b10000,
      :update => 0b11100,
      :foo    => 0b11110,
    }
  end
  def test_default_action
    sd = Bike::Set::Dynamic.new(
      :workflow => 'test_default_action',
      :group    => ['roy']
    )
    def sd.meta_admins
      ['frank']
    end
    sd.load(
      '20091122_0001' => {'_owner' => 'carl'},
      '20091122_0002' => {'_owner' => 'frank'}
    )
    assert_equal('carl', sd.item('20091122_0001')[:owner])
    assert_equal('frank', sd.item('20091122_0002')[:owner])

    Bike.client = nil
    assert_equal(
      nil,
      sd.default_action,
      'Workflow#default_action should return a permitted action for the client'
    )

    Bike.client = 'carl' # carl is not the member of the group
    assert_equal(
      :foo,
      sd.default_action,
      'Workflow#default_action should return a permitted action for the client'
    )
    assert_equal(
      :update,
      sd.item('20091122_0001').default_action,
      'Workflow#default_action should see the given conds'
    )

    Bike.client = 'roy' # roy belongs to the group
    assert_equal(
      :create,
      sd.default_action,
      'Workflow#default_action should return a permitted action for the client'
    )

    Bike.client = 'frank' # frank is the admin
    assert_equal(
      :read,
      sd.default_action,
      'Workflow#default_action should return a permitted action for the client'
    )
  end

  class Bike::Workflow::Test_default_sub_items < Bike::Workflow
    DEFAULT_SUB_ITEMS = {
      '_timestamp' => {:klass => 'meta-timestamp'},
    }
  end
  def test_default_sub_items
    sd = Bike::Set::Dynamic.new(
      :workflow => 'test_default_sub_items'
    )
    assert_equal(
      {'_timestamp' => {:klass => 'meta-timestamp'}},
      sd[:item]['default'][:item],
      'Workflow#default_sub_items should supply DEFAULT_SUB_ITEMS to sd[:item][*]'
    )

    sd = Bike::Set::Dynamic.new(
      :workflow => 'test_default_sub_items',
      :item     => {
        'default' => {
          :item => {
            '_timestamp' => {:klass => 'meta-timestamp', :can_update => true},
            'foo'        => {:klass => 'text'},
          },
        },
      }
    )
    assert_equal(
      {
        '_timestamp' => {:klass => 'meta-timestamp', :can_update => true},
        'foo'        => {:klass => 'text'},
      },
      sd[:item]['default'][:item],
      'Workflow#default_sub_items should be overriden by sd[:item]'
    )
  end

  def test_login
    Bike.client = nil
    res = Bike::Set::Static::Folder.root.item('foo', 'main').workflow.send(
      :_p_login,
      {'id' => 'test', 'pw' => 'test', :conds => {:id => '20100222_0123'}, :dest_action => 'update'}
    )
    assert_equal(
      'test',
      Bike.client,
      'Bike#login should set Bike.client given a valid pair of user/password'
    )
    assert_match(
      %r{/foo/20100222/123/update.html},
      res[1]['Location'],
      'Bike#login should return a proper location header'
    )
  end

  def test_login_default_action
    Bike.client = nil
    res = Bike::Set::Static::Folder.root.item('foo', 'main').workflow.send(
      :_p_login,
      {'id' => 'test', 'pw' => 'test', :conds => {:id => '20100222_0123'}}
    )
    assert_match(
      %r{/foo/20100222/123/index.html},
      res[1]['Location'],
      "Bike#login should set 'index' as the default action of a location"
    )
  end

  def test_login_with_wrong_account
    Bike.client = nil

    assert_raise(
      Bike::Error::Forbidden,
      'Bike#login should raise Error::Forbidden given a non-existent user'
    ) {
      res = Bike::Set::Static::Folder.root.item('foo', 'main').workflow.send(
        :_p_login,
        {'id' => 'non-existent', 'pw' => 'test'}
      )
    }
    assert_equal(
      'nobody',
      Bike.client,
      'Bike#login should not set Bike.client with a non-existent user'
    )

    assert_raise(
      Bike::Error::Forbidden,
      'Bike#login should raise Error::Forbidden given a empty password'
    ) {
      res = Bike::Set::Static::Folder.root.item('foo', 'main').workflow.send(
        :_p_login,
        {'id' => 'test', 'pw' => nil}
      )
    }
    assert_equal(
      'nobody',
      Bike.client,
      'Bike#login should not set Bike.client with an empty password'
    )

    assert_raise(
      Bike::Error::Forbidden,
      'Bike#login should raise Error::Forbidden given a wrong password'
    ) {
      res = Bike::Set::Static::Folder.root.item('foo', 'main').workflow.send(
        :_p_login,
        {
          'id' => 'test',
          'pw' => 'wrong',
          :conds => {:id => '20100222_0123'},
          :dest_action => 'update'
        }
      )
    }
    assert_equal(
      'nobody',
      Bike.client,
      'Bike#login should not set Bike.client with a wrong password'
    )
  end

  def test_logout
    Bike.client = 'frank'
    res = Bike::Set::Static::Folder.root.item('foo', 'main').workflow.send(
      :_p_logout,
      {'id' => 'test', 'pw' => 'test', :conds => {:id => '20100222_0123'}, :token => Bike.token}
    )
    assert_equal(
      'nobody',
      Bike.client,
      'Bike#logout should clear Bike.client'
    )
    assert_match(
      %r{/foo/20100222/123/index.html},
      res[1]['Location'],
      'Bike#logout should return a proper location header'
    )
  end

end
