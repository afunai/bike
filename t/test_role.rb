# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class TC_Role < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_owner
    assert_equal(
      'root',
      Bike::Set::Static::Folder.root[:owner],
      "Field#[:owner] should return 'root' for the root folder"
    )

    assert_equal(
      'frank',
      Bike::Set::Static::Folder.root.item('foo', 'main', '20091120_0001')[:owner],
      'Field#[:owner] should return @meta[:owner] if available'
    )
    assert_equal(
      'frank',
      Bike::Set::Static::Folder.root.item('foo', 'main', '20091120_0001', 'replies')[:owner],
      'Field#[:owner] should return parent[:owner] if @meta[:owner] is nil'
    )
    assert_equal(
      'carl',
      Bike::Set::Static::Folder.root.item('foo', 'main', '20091120_0001', 'replies', '20091201_0001')[:owner],
      'Field#[:owner] should return @meta[:owner] if available'
    )

    assert_equal(
      'root',
      Bike::Set::Static::Folder.root.item('foo', 'bar')[:owner],
      'Field#[:owner] should return parent[:owner] if @meta[:owner] is nil'
    )
    assert_equal(
      'root',
      Bike::Set::Static::Folder.root.item('foo', 'bar', 'main')[:owner],
      'Field#[:owner] should return parent[:owner] if @meta[:owner] is nil'
    )
    assert_equal(
      'carl',
      Bike::Set::Static::Folder.root.item('foo', 'bar', 'main', '20091120_0001')[:owner],
      'Field#[:owner] should return @meta[:owner] if available'
    )
    assert_equal(
      'carl',
      Bike::Set::Static::Folder.root.item('foo', 'bar', 'main', '20091120_0001', 'name')[:owner],
      'Field#[:owner] should return parent[:owner] if @meta[:owner] is nil'
    )
  end

  def test_owners
    assert_equal(
      ['root'],
      Bike::Set::Static::Folder.root[:owners],
      "Field#[:owners] should return ['root'] for the root folder"
    )
    assert_equal(
      ['root'],
      Bike::Set::Static::Folder.root.item('foo')[:owners],
      'Field#[:owners] should return all the owners of the ancestor fields'
    )
    assert_equal(
      ['root'],
      Bike::Set::Static::Folder.root.item('foo', 'bar', 'main')[:owners],
      'Field#[:owners] should return all the owners of the ancestor fields'
    )
    assert_equal(
      ['root', 'carl'],
      Bike::Set::Static::Folder.root.item('foo', 'bar', 'main', '20091120_0001')[:owners],
      'Field#[:owners] should return all the owners of the ancestor fields'
    )
  end

  def test_admins
    assert_equal(
      ['root'],
      Bike::Set::Static::Folder.root[:admins],
      "Field#[:admins] should return ['root'] for the root folder"
    )
    assert_equal(
      ['root', 'frank'],
      Bike::Set::Static::Folder.root.item('foo')[:admins],
      'Field#[:admins] should include @meta[:admin] if available'
    )
    assert_equal(
      ['root', 'frank'],
      Bike::Set::Static::Folder.root.item('foo', 'main')[:admins],
      'Field#[:admins] should return parent[:admins] if @meta[:admin] is nil'
    )
    assert_equal(
      ['root', 'frank'],
      Bike::Set::Static::Folder.root.item('foo', 'main', '20091120_0001')[:admins],
      'Field#[:admins] should return parent[:admins] if @meta[:admin] is nil'
    )

    assert_equal(
      ['root', 'frank'],
      Bike::Set::Static::Folder.root.item('foo', 'bar')[:admins],
      'Field#[:admins] should return parent[:admins] if @meta[:admin] is nil'
    )
    assert_equal(
      ['root', 'frank'],
      Bike::Set::Static::Folder.root.item('foo', 'bar', 'main')[:admins],
      'Field#[:admins] should return parent[:admins] if @meta[:admin] is nil'
    )
    assert_equal(
      ['root', 'frank'],
      Bike::Set::Static::Folder.root.item('foo', 'bar', 'main', '20091120_0001')[:admins],
      'Field#[:admins] should return @meta[:admins] if available'
    )
    assert_equal(
      ['root', 'frank'],
      Bike::Set::Static::Folder.root.item('foo', 'bar', 'main', '20091120_0001', 'name')[:admins],
      'Field#[:admins] should return @meta[:admins] if available'
    )
  end

  def test_group
    assert_equal(
      [],
      Bike::Set::Static::Folder.root[:group],
      "Field#[:group] should return [] for the root folder"
    )
    assert_equal(
      ['roy', 'jim'],
      Bike::Set::Static::Folder.root.item('foo')[:group],
      'Field#[:group] should return @meta[:group] if available'
    )
    assert_equal(
      ['roy', 'jim'],
      Bike::Set::Static::Folder.root.item('foo', 'main')[:group],
      'Field#[:group] should return @meta[:group] of the nearest folder'
    )
    assert_equal(
      ['roy', 'jim'],
      Bike::Set::Static::Folder.root.item('foo', 'main', '20091120_0001')[:group],
      'Field#[:group] should return @meta[:group] of the nearest folder'
    )

    assert_equal(
      ['carl', 'don'],
      Bike::Set::Static::Folder.root.item('foo', 'bar')[:group],
      'Field#[:group] should return @meta[:group] if available'
    )
    assert_equal(
      ['carl', 'don'],
      Bike::Set::Static::Folder.root.item('foo', 'bar', 'main')[:group],
      'Field#[:group] should return @meta[:group] of the nearest folder'
    )
  end

  def test_roles_of_nobody
    Bike.client = nil
    assert_equal(
      0b00001,
      Bike::Set::Static::Folder.root[:roles],
      'Field#[:roles] should return the roles of the client on the field'
    )
    assert_equal(
      0b00001,
      Bike::Set::Static::Folder.root.item('foo')[:roles],
      'Field#[:roles] should return the roles of the client on the field'
    )
    assert_equal(
      0b00001,
      Bike::Set::Static::Folder.root.item('foo', 'main')[:roles],
      'Field#[:roles] should return the roles of the client on the field'
    )
    assert_equal(
      0b00001,
      Bike::Set::Static::Folder.root.item('foo', 'main', '20091120_0001')[:roles],
      'Field#[:roles] should return the roles of the client on the field'
    )
    assert_equal(
      0b00001,
      Bike::Set::Static::Folder.root.item('foo', 'bar')[:roles],
      'Field#[:roles] should return the roles of the client on the field'
    )
  end

  def test_roles_of_frank
    Bike.client = 'frank'
    assert_equal(
      0b00010,
      Bike::Set::Static::Folder.root[:roles],
      'Field#[:roles] should return the roles of the client on the field'
    )
    assert_equal(
      0b10010,
      Bike::Set::Static::Folder.root.item('foo')[:roles],
      'Field#[:roles] should return the roles of the client on the field'
    )
    assert_equal(
      0b10010,
      Bike::Set::Static::Folder.root.item('foo', 'main')[:roles],
      'Field#[:roles] should return the roles of the client on the field'
    )
    assert_equal(
      0b10110,
      Bike::Set::Static::Folder.root.item('foo', 'main', '20091120_0001')[:roles],
      'Field#[:roles] should return the roles of the client on the field'
    )
    assert_equal(
      0b10010,
      Bike::Set::Static::Folder.root.item('foo', 'bar')[:roles],
      'Field#[:roles] should return the roles of the client on the field'
    )
  end

  def test_roles_of_roy
    Bike.client = 'roy'
    assert_equal(
      0b00010,
      Bike::Set::Static::Folder.root[:roles],
      'Field#[:roles] should return the roles of the client on the field'
    )
    assert_equal(
      0b01010,
      Bike::Set::Static::Folder.root.item('foo')[:roles],
      'Field#[:roles] should return the roles of the client on the field'
    )
    assert_equal(
      0b01010,
      Bike::Set::Static::Folder.root.item('foo', 'main')[:roles],
      'Field#[:roles] should return the roles of the client on the field'
    )
    assert_equal(
      0b01010,
      Bike::Set::Static::Folder.root.item('foo', 'main', '20091120_0001')[:roles],
      'Field#[:roles] should return the roles of the client on the field'
    )
    assert_equal(
      0b00010,
      Bike::Set::Static::Folder.root.item('foo', 'bar')[:roles],
      'Field#[:roles] should return the roles of the client on the field'
    )
  end

end
