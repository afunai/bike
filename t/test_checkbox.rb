# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Checkbox < Test::Unit::TestCase

	def setup
		meta = nil
		Sofa::Parser.gsub_scalar("$(foo checkbox bar,baz,qux :'baz' mandatory)") {|id,m|
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
			'Checkbox#initialize should set :options from the csv token'
		)
		assert_equal(
			true,
			@f[:mandatory],
			'Checkbox#initialize should set :default from the token'
		)
		assert_equal(
			'baz',
			@f[:default],
			'Checkbox#initialize should set :default from the token'
		)
	end

	def test_val_cast
		assert_equal(
			[],
			@f.val,
			'Checkbox#val_cast should cast the given val to String'
		)

		@f.load 123
		assert_equal(
			['123'],
			@f.val,
			'Checkbox#val_cast should cast the given val to String'
		)

		@f.load ['',123,456]
		assert_equal(
			['123','456'],
			@f.val,
			'Checkbox#val_cast should ignore empty vals'
		)
	end

	def test_get
		@f.load ''
		assert_equal(
			'',
			@f.get,
			'Checkbox#get should return proper string'
		)
		assert_equal(
			<<_html.chomp,
<input type="hidden" name="[]" value="" />
<span class="checkbox">
	<input type="checkbox" id="-bar" name="[]" value="bar" />
	<label for="-bar">bar</label>
</span>
<span class="checkbox">
	<input type="checkbox" id="-baz" name="[]" value="baz" />
	<label for="-baz">baz</label>
</span>
<span class="checkbox">
	<input type="checkbox" id="-qux" name="[]" value="qux" />
	<label for="-qux">qux</label>
</span>
_html
			@f.get(:action => :create),
			'Checkbox#get should return proper string'
		)

		@f.load ['baz','qux']
		assert_equal(
			'baz, qux',
			@f.get,
			'Checkbox#get should return proper string'
		)
		assert_equal(
			<<_html.chomp,
<input type="hidden" name="[]" value="" />
<span class="checkbox">
	<input type="checkbox" id="-bar" name="[]" value="bar" />
	<label for="-bar">bar</label>
</span>
<span class="checkbox">
	<input type="checkbox" id="-baz" name="[]" value="baz" checked />
	<label for="-baz">baz</label>
</span>
<span class="checkbox">
	<input type="checkbox" id="-qux" name="[]" value="qux" checked />
	<label for="-qux">qux</label>
</span>
_html
			@f.get(:action => :update),
			'Checkbox#get should return proper string'
		)

		@f.load 'non-exist'
		assert_equal(
			<<_html.chomp,
<input type="hidden" name="[]" value="" />
<span class="checkbox error">
	<input type="checkbox" id="-bar" name="[]" value="bar" />
	<label for="-bar">bar</label>
</span>
<span class="checkbox error">
	<input type="checkbox" id="-baz" name="[]" value="baz" />
	<label for="-baz">baz</label>
</span>
<span class="checkbox error">
	<input type="checkbox" id="-qux" name="[]" value="qux" />
	<label for="-qux">qux</label>
</span>
<div class=\"error\">no such option</div>
_html
			@f.get(:action => :update),
			'Checkbox#get should return proper string'
		)
	end

	def test_errors
		@f.load ''
		@f[:mandatory] = nil
		assert_equal(
			[],
			@f.errors,
			'Checkbox#errors should return the errors of the current val'
		)
		@f[:mandatory] = true
		assert_equal(
			['mandatory'],
			@f.errors,
			'Checkbox#errors should return the errors of the current val'
		)

		@f.load 'non-exist'
		@f[:mandatory] = nil
		assert_equal(
			['no such option'],
			@f.errors,
			'Checkbox#errors should return the errors of the current val'
		)
	end

end
