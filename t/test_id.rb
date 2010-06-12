# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class TC_Id < Test::Unit::TestCase

  def setup
    meta = nil
    Runo::Parser.gsub_scalar('$(foo meta-id 3 1..5)') {|id, m|
      meta = m
      ''
    }
    @f = Runo::Field.instance meta

    Runo.current[:base] = nil
  end

  def teardown
  end

  def test_meta
    assert_equal(
      3,
      @f[:size],
      'Meta::Id#initialize should set :size from the token'
    )
    assert_equal(
      1,
      @f[:min],
      'Meta::Id#initialize should set :min from the range token'
    )
    assert_equal(
      5,
      @f[:max],
      'Meta::Id#initialize should set :max from the range token'
    )
  end

  def test_val_cast
    assert_equal(
      '',
      @f.val,
      'Meta::Id#val_cast should cast the given val to String'
    )

    @f.load 123
    assert_equal(
      '123',
      @f.val,
      'Meta::Id#val_cast should cast the given val to String'
    )
  end

  def test_new_id?
    @f[:parent] = Runo::Set::Static.new(:id => '20100526_0001')
    assert_equal(
      false,
      @f.send(:new_id?),
      'Meta::Id#new_id? should return whether the ancestors is new or not'
    )

    @f[:parent] = Runo::Set::Static.new(:id => '_001')
    assert_equal(
      true,
      @f.send(:new_id?),
      'Meta::Id#new_id? should return whether the ancestors is new or not'
    )
  end

  def test_get
    @f[:parent] = Runo::Set::Static.new(:id => '_001')
    assert_equal(
      '<input type="text" name="" value="" size="3" class="meta-id" />',
      @f.get(:action => :create),
      'Meta::Id#_g_create should return <input> if the ancestor is new'
    )

    @f[:parent] = Runo::Set::Static.new(:id => '20100526_0001')
    assert_equal(
      '',
      @f.get(:action => :create),
      'Meta::Id#_g_create should return val if the ancestor is not new'
    )

    @f.load 'bar'
    assert_equal(
      'bar',
      @f.get,
      'Meta::Id#get should return proper string'
    )

    @f[:parent] = Runo::Set::Static.new(:id => '_001')
    assert_equal(
      '<input type="text" name="" value="bar" size="3" class="meta-id" />',
      @f.get(:action => :update),
      'Meta::Id#_g_update should return <input> if the ancestor is new'
    )

    @f[:parent] = Runo::Set::Static.new(:id => '20100526_0001')
    assert_equal(
      'bar',
      @f.get(:action => :update),
      'Meta::Id#_g_update should return val if the ancestor is not new'
    )

    @f.load '<bar>'
    assert_equal(
      '&lt;bar&gt;',
      @f.get,
      'Meta::Id#get should escape the special characters'
    )

    @f[:parent] = Runo::Set::Static.new(:id => '_001')
    @f.load '<bar>'
    assert_equal(
      '<input type="text" name="" value="&lt;bar&gt;" size="3" class="meta-id error" /><span class="error_message">malformatted id</span>' + "\n",
      @f.get(:action => :update),
      'Meta::Id#get should escape the special characters'
    )
  end

  def test_post_new_ancestor
    @f[:parent] = Runo::Set::Static.new(:id => '_001')
    @f.create 'frank'
    assert_equal(
      'frank',
      @f.val,
      'Meta::Id#post should create like a normal field'
    )

    @f.update 'bobby'
    assert_equal(
      'bobby',
      @f.val,
      'Meta::Id#post should update the current val if the ancestor is new'
    )
  end

  def test_post_old_ancestor
    @f[:parent] = Runo::Set::Static.new(:id => '20100526_0001')
    @f.load 'frank'

    @f.update 'bobby'
    assert_equal(
      'frank',
      @f.val,
      'Meta::Id#post should not update the current val if the ancestor is not new'
    )
  end

  def test_errors
    @f.load '<a'
    assert_equal(
      ['malformatted id'],
      @f.errors,
      'Meta::Id#errors should return the errors of the current val'
    )

    @f.load '123a'
    assert_equal(
      ['malformatted id'],
      @f.errors,
      'Meta::Id#errors should return the errors of the current val'
    )

    @f.load 'abcdefghijk'
    assert_equal(
      ['too long: 5 characters maximum'],
      @f.errors,
      'Meta::Id#errors should return the errors of the current val'
    )

    @f.load 'frank'
    assert_equal(
      [],
      @f.errors,
      'Meta::Id#errors should return an empty array if there is no error'
    )
  end

  def test_errors_duplicate_id
    Runo.client = 'root'
    sd = Runo::Set::Static::Folder.root.item('_users', 'main')

    sd.update(
      '_001' => {:action => :create, '_id' => 'test'}
    )
    assert_equal(
      ['duplicate id: test'],
      sd.item('_001', '_id').errors,
      'Meta::Id#errors should return an error if the current val is duplicated in the sd'
    )

    sd.update(
      '_001' => {:action => :create, '_id' => 'frank'}
    )
    assert_equal(
      [],
      sd.item('_001', '_id').errors,
      'Meta::Id#errors should return no error if the current val is unique in the sd'
    )

    f = Runo::Set::Static::Folder.root.item('_users', 'main', 'test', '_id')
    f.update 'test'
    assert_equal(
      [],
      f.errors,
      'Meta::Id#errors should return no error if the current val is unchanged'
    )
  end

end
