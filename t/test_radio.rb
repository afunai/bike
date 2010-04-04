# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Radio < Test::Unit::TestCase

	def setup
		meta = nil
		Sofa::Parser.gsub_scalar("$(foo radio bar,baz,qux :'baz' mandatory)") {|id,m|
			meta = m
			''
		}
		@f = Sofa::Field.instance meta
	end

	def teardown
	end

	def test_meta
		assert_equal(
			['bar','baz','qux'],
			@f[:options],
			'Radio#initialize should set :options from the csv token'
		)
		assert_equal(
			true,
			@f[:mandatory],
			'Radio#initialize should set :default from the token'
		)
		assert_equal(
			'baz',
			@f[:default],
			'Radio#initialize should set :default from the token'
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
			<<_html.chomp,
<span class="radio">
	<input type="radio" id="-bar" name="" value="bar" />
	<label for="-bar">bar</label>
</span>
<span class="radio">
	<input type="radio" id="-baz" name="" value="baz" />
	<label for="-baz">baz</label>
</span>
<span class="radio">
	<input type="radio" id="-qux" name="" value="qux" />
	<label for="-qux">qux</label>
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
			<<_html.chomp,
<span class="radio">
	<input type="radio" id="-bar" name="" value="bar" />
	<label for="-bar">bar</label>
</span>
<span class="radio">
	<input type="radio" id="-baz" name="" value="baz" />
	<label for="-baz">baz</label>
</span>
<span class="radio">
	<input type="radio" id="-qux" name="" value="qux" checked />
	<label for="-qux">qux</label>
</span>
_html
			@f.get(:action => :update),
			'Radio#get should return proper string'
		)

		@f.load 'non-exist'
		assert_equal(
			<<_html.chomp,
<span class="radio error">
	<input type="radio" id="-bar" name="" value="bar" />
	<label for="-bar">bar</label>
</span>
<span class="radio error">
	<input type="radio" id="-baz" name="" value="baz" />
	<label for="-baz">baz</label>
</span>
<span class="radio error">
	<input type="radio" id="-qux" name="" value="qux" />
	<label for="-qux">qux</label>
</span>
<div class=\"error\">no such option</div>
_html
			@f.get(:action => :update),
			'Radio#get should return proper string'
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
