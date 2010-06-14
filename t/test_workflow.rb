# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class TC_Workflow < Test::Unit::TestCase

  class Runo::Workflow::Foo < Runo::Workflow
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
    sd = Runo::Set::Dynamic.new
    assert_instance_of(
      Runo::Workflow,
      Runo::Workflow.instance(sd),
      'Runo::Workflow.instance should return a Workflow instance if sd[:workflow] is nil'
    )
    sd = Runo::Set::Static::Folder.root.item('foo', 'main')
    assert_instance_of(
      Runo::Workflow::Blog,
      Runo::Workflow.instance(sd),
      'Runo::Workflow.instance should return a instance according to sd[:workflow]'
    )

    assert_equal(
      sd,
      Runo::Workflow.instance(sd).sd,
      'Runo::Workflow.instance should set @sd'
    )
  end

  def test_roles
    assert_equal(
      %w(none),
      Runo::Workflow.roles(0b00001),
      'Runo::Workflow.roles should return a human-readable string of the given roles'
    )
    assert_equal(
      %w(owner),
      Runo::Workflow.roles(0b00100),
      'Runo::Workflow.roles should return a human-readable string of the given roles'
    )
    assert_equal(
      %w(admin),
      Runo::Workflow.roles(0b10000),
      'Runo::Workflow.roles should return a human-readable string of the given roles'
    )
    assert_equal(
      %w(admin owner user),
      Runo::Workflow.roles(0b10110),
      'Runo::Workflow.roles should return a human-readable string of the given roles'
    )
  end

  def test_wf_permit_guest?
    wf = Runo::Workflow::Foo.new(nil)
    assert(
      !wf.send(:'permit?', Runo::Workflow::ROLE_USER, :create),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Runo::Workflow::ROLE_USER, :read),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      !wf.send(:'permit?', Runo::Workflow::ROLE_USER, :update),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      !wf.send(:'permit?', Runo::Workflow::ROLE_USER, :delete),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
  end

  def test_wf_permit_owner?
    wf = Runo::Workflow::Foo.new(nil)
    assert(
      !wf.send(:'permit?', Runo::Workflow::ROLE_OWNER, :create),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Runo::Workflow::ROLE_OWNER, :read),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Runo::Workflow::ROLE_OWNER, :update),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      !wf.send(:'permit?', Runo::Workflow::ROLE_OWNER, :delete),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
  end

  def test_wf_permit_group?
    wf = Runo::Workflow::Foo.new(nil)
    assert(
      wf.send(:'permit?', Runo::Workflow::ROLE_GROUP, :create),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Runo::Workflow::ROLE_GROUP, :read),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      !wf.send(:'permit?', Runo::Workflow::ROLE_GROUP, :update),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Runo::Workflow::ROLE_GROUP, :delete),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
  end

  def test_wf_permit_admin?
    wf = Runo::Workflow::Foo.new(nil)
    assert(
      wf.send(:'permit?', Runo::Workflow::ROLE_ADMIN, :create),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Runo::Workflow::ROLE_ADMIN, :read),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Runo::Workflow::ROLE_ADMIN, :update),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
    assert(
      wf.send(:'permit?', Runo::Workflow::ROLE_ADMIN, :delete),
      'Set::Workflow#permit? should return whether it permits the client the action or not'
    )
  end

  def test_wf_permit_login_action?
    wf = Runo::Workflow::Foo.new(nil)
    assert(
      wf.send(:'permit?', Runo::Workflow::ROLE_USER, :login),
      'Set::Workflow#permit? should always permit :login'
    )
    assert(
      wf.send(:'permit?', Runo::Workflow::ROLE_OWNER, :login),
      'Set::Workflow#permit? should always permit :login'
    )
    assert(
      wf.send(:'permit?', Runo::Workflow::ROLE_GROUP, :login),
      'Set::Workflow#permit? should always permit :login'
    )
    assert(
      wf.send(:'permit?', Runo::Workflow::ROLE_ADMIN, :login),
      'Set::Workflow#permit? should always permit :login'
    )
  end

  def test_wf_permit_abnormal_action?
    wf = Runo::Workflow::Foo.new(nil)
    assert(
      !wf.send(:'permit?', Runo::Workflow::ROLE_ADMIN, :'non-exist'),
      'Set::Workflow#permit? should always return false for non-exist actions'
    )
  end

  def test_permit_nobody?
    sd = Runo::Set::Static::Folder.root.item('foo', 'bar', 'main')
    Runo.client = nil
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
    sd = Runo::Set::Static::Folder.root.item('foo', 'bar', 'main')
    Runo.client = 'don' # don belongs to the group of foo/bar/
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
    sd = Runo::Set::Static::Folder.root.item('foo', 'bar', 'main')
    Runo.client = 'carl' # carl belongs to the group of foo/bar/, and the owner of the item #0001
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
    sd = Runo::Set::Static::Folder.root.item('foo', 'bar', 'main')
    Runo.client = 'frank' # frank is an admin of foo/bar/
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
    sd = Runo::Set::Static::Folder.root.item('foo', 'bar', 'main')
    Runo.client = 'frank'
    assert(
      !sd.permit?(:'****'),
      'frank should not **** on the stage'
    )
  end

  class Runo::Workflow::Test_default_action < Runo::Workflow
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
    sd = Runo::Set::Dynamic.new(
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

    Runo.client = nil
    assert_equal(
      nil,
      sd.default_action,
      'Workflow#default_action should return a permitted action for the client'
    )

    Runo.client = 'carl' # carl is not the member of the group
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

    Runo.client = 'roy' # roy belongs to the group
    assert_equal(
      :create,
      sd.default_action,
      'Workflow#default_action should return a permitted action for the client'
    )

    Runo.client = 'frank' # frank is the admin
    assert_equal(
      :read,
      sd.default_action,
      'Workflow#default_action should return a permitted action for the client'
    )
  end

  class Runo::Workflow::Test_default_sub_items < Runo::Workflow
    DEFAULT_SUB_ITEMS = {
      '_timestamp' => {:klass => 'meta-timestamp'},
    }
  end
  def test_default_sub_items
    sd = Runo::Set::Dynamic.new(
      :workflow => 'test_default_sub_items'
    )
    assert_equal(
      {'_timestamp' => {:klass => 'meta-timestamp'}},
      sd[:item]['default'][:item],
      'Workflow#default_sub_items should supply DEFAULT_SUB_ITEMS to sd[:item][*]'
    )

    sd = Runo::Set::Dynamic.new(
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

end
