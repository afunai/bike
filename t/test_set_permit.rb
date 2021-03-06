# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class TC_Set_Permit < Test::Unit::TestCase

  class Bike::Workflow::Test_set_permit < Bike::Workflow
    DEFAULT_SUB_ITEMS = {
      '_owner'   => {:klass => 'meta-owner'},
    }
    PERM = {
      :create => 0b11110,
      :read   => 0b11100,
      :update => 0b11100,
      :delete => 0b11100,
    }
  end

  def setup
    @sd = Bike::Set::Dynamic.new(
      :workflow => 'test_set_permit',
      :item_arg => {
        :item => {'foo' => {:klass => 'text'}}
      }
    ).load(
      '20100228_0001' => {'_owner' => 'frank', 'foo' => 'abc'},
      '20100228_0002' => {'_owner' => 'carl', 'foo' => 'def'}
    )
    @sd[:owner] = 'frank'
    @sd.send(:item_instance, '_0001') # create a new pending item
  end

  def teardown
  end

  def test_permit_get_by_frank
    Bike.client = 'frank'
    assert_equal(
      0b00110,
      @sd[:roles],
      'frank should be the owner of the set and a logged-in user'
    )
    assert(
      @sd.send(
        :'permit_get?',
        {
          :action => :update,
          :conds  => {:id => '20100228_0001'},
        }
      ),
      'Set#permit_get? should allow frank to get an update form of his own item'
    )
    assert(
      @sd.send(
        :'permit_get?',
        {
          :action => :update,
        }
      ),
      'Set#permit_get? should allow frank to get an update form of any items in his set'
    )

    assert(
      @sd.send(
        :'permit_get?',
        {
          :action => :update,
          :conds  => {:id => '_0001'},
        }
      ),
      'Set#permit_get? should allow frank to get an update form of a new pending item'
    )
    assert(
      @sd.item('_0001').send(
        :'permit_get?',
        {
          :action => :update,
        }
      ),
      'frank should be allowed to get a sub-item of the pending item'
    )
  end

  def test_permit_get_by_carl
    Bike.client = 'carl'
    assert_equal(
      0b00010,
      @sd[:roles],
      'carl should be a logged-in user'
    )
    assert(
      !@sd.send(
        :'permit_get?',
        {
          :action => :update,
          :conds  => {:id => '20100228_0001'},
        }
      ),
      "Set#permit_get? should not allow carl to get an update form of frank's item"
    )
    assert(
      !@sd.item('20100228_0001').send(
        :'permit_get?',
        {
          :action => :update,
        }
      ),
      "carl should not be allowed to get a sub-item of frank's item"
    )
    assert(
      @sd.send(
        :'permit_get?',
        {
          :action => :update,
          :conds  => {:id => '20100228_0002'},
        }
      ),
      'Set#permit_get? should allow carl to get an update form of his own item'
    )

    assert(
      @sd.send(
        :'permit_get?',
        {
          :action => :update,
          :conds  => {:id => '_0001'},
        }
      ),
      'Set#permit_get? should allow carl to get an update form of a new pending item'
    )
    assert(
      @sd.item('_0001').send(
        :'permit_get?',
        {
          :action => :update,
        }
      ),
      'carl should be allowed to get a sub-item of the pending item'
    )
  end

  def test_permit_post_by_frank
    Bike.client = 'frank'
    assert_equal(
      0b00110,
      @sd[:roles],
      'frank should be the owner of the set and a logged-in user'
    )
    assert(
      @sd.send(
        :'permit_post?',
        :update,
        {
          :action         => :update,
          '20100228_0001' => {},
        }
      ),
      'Set#permit_post? should allow frank to update his own item'
    )
    assert(
      @sd.send(
        :'permit_post?',
        :update,
        {
          :action         => :update,
          '20100228_0002' => {},
        }
      ),
      'Set#permit_post? should allow frank to update any item in his set'
    )
    assert(
      @sd.send(
        :'permit_post?',
        :update,
        {
          :action => :update,
          '_0001' => {'foo' => 'FOO'},
        }
      ),
      'Set#permit_post? should allow frank to create/update a new item'
    )
  end

  def test_permit_post_by_carl
    Bike.client = 'carl'
    assert_equal(
      0b00010,
      @sd[:roles],
      'carl should be a logged-in user'
    )
    assert(
      !@sd.send(
        :'permit_post?',
        :update,
        {
          :action         => :update,
          '20100228_0001' => {},
        }
      ),
      "Set#permit_post? should not allow carl to update frank's item"
    )
    assert(
      !@sd.item('20100228_0001').send(
        :'permit_post?',
        :update,
        {'foo' => 'updated'}
      ),
      "carl should not be allowed to post a sub-item of frank's item"
    )

    assert(
      @sd.send(
        :'permit_post?',
        :update,
        {
          :action         => :update,
          '20100228_0002' => {},
        }
      ),
      'Set#permit_post? should allow carl to update his own item'
    )
    assert(
      @sd.send(
        :'permit_post?',
        :update,
        {
          :action => :update,
          '_0001' => {'foo' => 'FOO'},
        }
      ),
      'Set#permit_post? should allow carl to create/update a new item'
    )
    assert(
      @sd.item('_0001').send(
        :'permit_post?',
        :update,
        {'foo' => 'updated'}
      ),
      'carl should be allowed to post a sub-item of the new item'
    )
  end

end
