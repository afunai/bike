# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Select < Test::Unit::TestCase

	def setup
		meta = nil
		Sofa::Parser.gsub_scalar("$(foo select bar,baz,qux :'baz' mandatory)") {|id,m|
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
			'Select#initialize should set :options from the csv token'
		)
		assert_equal(
			true,
			@f[:mandatory],
			'Select#initialize should set :default from the token'
		)
		assert_equal(
			'baz',
			@f[:default],
			'Select#initialize should set :default from the token'
		)
	end

	def test_val_cast
		assert_equal(
			'',
			@f.val,
			'Select#val_cast should cast the given val to String'
		)

		@f.load 123
		assert_equal(
			'123',
			@f.val,
			'Select#val_cast should cast the given val to String'
		)
	end

	def test_get
		@f.load ''
		assert_equal(
			'',
			@f.get,
			'Select#get should return proper string'
		)
		assert_equal(
			<<_html.chomp,
<select name="" class="">
	<option value="">please select</option>
	<option>bar</option>
	<option>baz</option>
	<option>qux</option>
</select>
_html
			@f.get(:action => :create),
			'Select#get should return proper string'
		)

		@f.load 'qux'
		assert_equal(
			'qux',
			@f.get,
			'Select#get should return proper string'
		)
		assert_equal(
			<<_html.chomp,
<select name="" class="">
	<option>bar</option>
	<option>baz</option>
	<option selected>qux</option>
</select>
_html
			@f.get(:action => :update),
			'Select#get should return proper string'
		)
	end

	def test_errors
		@f.load ''
		@f[:mandatory] = nil
		assert_equal(
			[],
			@f.errors,
			'Select#errors should return the errors of the current val'
		)
		@f[:mandatory] = true
		assert_equal(
			['mandatory'],
			@f.errors,
			'Select#errors should return the errors of the current val'
		)

		@f.load 'boo'
		@f[:mandatory] = nil
		assert_equal(
			['no such option'],
			@f.errors,
			'Select#errors should return the errors of the current val'
		)
	end

end
