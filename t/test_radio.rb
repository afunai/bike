# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class TC_Radio < Test::Unit::TestCase

  def setup
    meta = nil
    Bike::Parser.gsub_scalar("$(foo radio bar, baz, qux :'baz' mandatory)") {|id, m|
      meta = m
      ''
    }
    @f = Bike::Field.instance meta
  end

  def teardown
  end

  def test_meta
    assert_equal(
      ['bar', 'baz', 'qux'],
      @f[:options],
      'Radio#initialize should set :options from the csv token'
    )
    assert_equal(
      true,
      @f[:mandatory],
      'Radio#initialize should set :mandatory from the misc token'
    )
    assert_equal(
      'baz',
      @f[:default],
      'Radio#initialize should set :default from the token'
    )
  end

  def test_meta_options_from_range
    meta = nil
    Bike::Parser.gsub_scalar("$(foo radio 1..5)") {|id, m|
      meta = m
      ''
    }
    f = Bike::Field.instance meta
    assert_equal(
      ['1', '2', '3', '4', '5'],
      f[:options],
      'Radio#initialize should set :options from the range token'
    )

    meta = nil
    Bike::Parser.gsub_scalar("$(foo radio ..5)") {|id, m|
      meta = m
      ''
    }
    f = Bike::Field.instance meta
    assert_equal(
      ['0', '1', '2', '3', '4', '5'],
      f[:options],
      'Radio#initialize should set :options from the range token'
    )

    meta = nil
    Bike::Parser.gsub_scalar("$(foo radio 1..)") {|id, m|
      meta = m
      ''
    }
    f = Bike::Field.instance meta
    assert_equal(
      nil,
      f[:options],
      'Radio#initialize should not refer to the range token if there is no maximum'
    )
  end

  def test_val_cast
    assert_equal(
      '',
      @f.val,
      'Radio#val_cast should cast the given val to String'
    )

    @f.load 123
    assert_equal(
      '123',
      @f.val,
      'Radio#val_cast should cast the given val to String'
    )
  end

  def test_get
    @f.load ''
    assert_equal(
      '',
      @f.get,
      'Radio#get should return proper string'
    )
    assert_equal(
      <<_html,
<span class="radio">
  <input type="hidden" name="" value="" />
  <span class="item">
    <input type="radio" id="radio_-bar" name="" value="bar" />
    <label for="radio_-bar">bar</label>
  </span>
  <span class="item">
    <input type="radio" id="radio_-baz" name="" value="baz" />
    <label for="radio_-baz">baz</label>
  </span>
  <span class="item">
    <input type="radio" id="radio_-qux" name="" value="qux" />
    <label for="radio_-qux">qux</label>
  </span>
</span>
_html
      @f.get(:action => :create),
      'Radio#get should return proper string'
    )

    @f.load 'qux'
    assert_equal(
      'qux',
      @f.get,
      'Radio#get should return proper string'
    )
    assert_equal(
      <<_html,
<span class="radio">
  <input type="hidden" name="" value="" />
  <span class="item">
    <input type="radio" id="radio_-bar" name="" value="bar" />
    <label for="radio_-bar">bar</label>
  </span>
  <span class="item">
    <input type="radio" id="radio_-baz" name="" value="baz" />
    <label for="radio_-baz">baz</label>
  </span>
  <span class="item">
    <input type="radio" id="radio_-qux" name="" value="qux" checked />
    <label for="radio_-qux">qux</label>
  </span>
</span>
_html
      @f.get(:action => :update),
      'Radio#get should return proper string'
    )

    @f.load 'non-exist'
    assert_equal(
      <<_html,
<span class="radio error">
  <input type="hidden" name="" value="" />
  <span class="item">
    <input type="radio" id="radio_-bar" name="" value="bar" />
    <label for="radio_-bar">bar</label>
  </span>
  <span class="item">
    <input type="radio" id="radio_-baz" name="" value="baz" />
    <label for="radio_-baz">baz</label>
  </span>
  <span class="item">
    <input type="radio" id="radio_-qux" name="" value="qux" />
    <label for="radio_-qux">qux</label>
  </span>
<span class=\"error_message\">no such option</span>
</span>
_html
      @f.get(:action => :update),
      'Radio#get should return proper string'
    )
  end

  def test_get_escape
    @f[:options] = ['foo', '<bar>']
    @f.load '<bar>'
    assert_equal(
      '&lt;bar&gt;',
      @f.get,
      'Radio#get should escape the special characters'
    )
    assert_equal(
      <<_html,
<span class="radio">
  <input type="hidden" name="" value="" />
  <span class="item">
    <input type="radio" id="radio_-foo" name="" value="foo" />
    <label for="radio_-foo">foo</label>
  </span>
  <span class="item">
    <input type="radio" id="radio_-&lt;bar&gt;" name="" value="&lt;bar&gt;" checked />
    <label for="radio_-&lt;bar&gt;">&lt;bar&gt;</label>
  </span>
</span>
_html
      @f.get(:action => :update),
      'Radio#get should escape the special characters'
    )
  end

  def test_errors
    @f.load ''
    @f[:mandatory] = nil
    assert_equal(
      [],
      @f.errors,
      'Radio#errors should return the errors of the current val'
    )
    @f[:mandatory] = true
    assert_equal(
      ['mandatory'],
      @f.errors,
      'Radio#errors should return the errors of the current val'
    )

    @f.load 'non-exist'
    @f[:mandatory] = nil
    assert_equal(
      ['no such option'],
      @f.errors,
      'Radio#errors should return the errors of the current val'
    )
  end

end
