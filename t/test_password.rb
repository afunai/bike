# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class TC_Password < Test::Unit::TestCase

  def setup
    @f = Runo::Field.instance(
      :klass   => 'password',
      :default => 'secret',
      :size    => 16
    )
  end

  def teardown
  end

  def test_get
    @f.instance_variable_set(:@val, 'hello')

    assert_equal(
      '*****',
      @f.get(:action => :read),
      'Password#get should not return anything other than a dummy string'
    )
    assert_equal(
      <<'_html'.chomp,
<span class="password"><input type="password" name="" value="" size="16" /></span>
_html
      @f.get(:action => :create),
      'Password#get(:action => :create) should return an empty form'
    )

    @f.update 'abcdefg'
    assert_equal(
      '*******',
      @f.get(:action => :read),
      'Password#get should refer to @size as a length of the dummy string'
    )
    assert_equal(
      <<'_html'.chomp,
<span class="password"><input type="password" name="" value="" size="16" /></span>
_html
      @f.get(:action => :update),
      'Password#get(:action => :update) should return an empty form'
    )
  end

  def test_load_default
    @f.load_default
    assert_nil(
      @f.val,
      'Password#load_default should not load any value'
    )
  end

  def test_load
    @f.load 'foobar'
    assert_equal(
      'foobar',
      @f.val,
      'Password#load should not alter the loaded value'
    )
  end

  def test_create
    @f.create 'foobar'
    assert_not_equal(
      'foobar',
      @f.val,
      'Password#create should store the value as a crypted string'
    )
  end

  def test_create_empty
    @f.create nil
    assert_equal(
      :create,
      @f.action,
      'Password#create should set @action even if the val is empty'
    )
  end

  def test_update
    @f.load 'original'

    @f.update nil
    assert_equal(
      'original',
      @f.val,
      'Password#update should not update with nil'
    )

    @f.update ''
    assert_equal(
      'original',
      @f.val,
      'Password#update should not update with an empty string'
    )

    @f.update 'updated'
    assert_not_equal(
      'original',
      @f.val,
      'Password#update should update with a non-empty string'
    )
    assert_not_equal(
      'updated',
      @f.val,
      'Password#update should store the value as a crypted string'
    )
  end

  def test_errors_on_load
    Runo.client = 'root'

    @f[:min] = 1
    @f.load ''
    assert_equal(
      [],
      @f.errors,
      'Password#errors should not return the errors of a loaded val'
    )
  end

  def test_errors
    @f.create nil
    @f[:min] = 1
    assert_equal(
      ['mandatory'],
      @f.errors,
      'Password#errors should return the errors of the current val'
    )

    @f.create nil
    assert_equal(
      ['mandatory'],
      @f.errors,
      'Password#errors should keep the errors of the previous non-empty update'
    )

    @f.create 'a'
    @f[:min] = 1
    assert_equal(
      [],
      @f.errors,
      'Password#errors should return the errors of the current val'
    )
    @f[:min] = 2
    assert_equal(
      ['too short: 2 characters minimum'],
      @f.errors,
      'Password#errors should return the errors of the current val'
    )

    @f.update 'abcde'
    @f[:max] = 5
    assert_equal(
      [],
      @f.errors,
      'Password#errors should return the errors of the current val'
    )
    @f[:max] = 4
    assert_equal(
      ['too long: 4 characters maximum'],
      @f.errors,
      'Password#errors should return the errors of the current val'
    )

    @f.update nil
    assert_equal(
      ['too long: 4 characters maximum'],
      @f.errors,
      'Password#errors should keep the errors of the previous non-empty update'
    )

    @f.update 'abc'
    assert_equal(
      [],
      @f.errors,
      'Password#errors should return the errors of the current val'
    )
  end

end
