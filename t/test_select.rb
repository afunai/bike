# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Select < Test::Unit::TestCase

	def setup
		meta = nil
		Runo::Parser.gsub_scalar("$(foo select bar,baz,qux :'baz' mandatory)") {|id,m|
			meta = m
			''
		}
		@f = Runo::Field.instance meta
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
			'Select#initialize should set :mandatory from the misc token'
		)
		assert_equal(
			'baz',
			@f[:default],
			'Select#initialize should set :default from the token'
		)
	end

	def test_meta_options_from_range
		meta = nil
		Runo::Parser.gsub_scalar("$(foo select 1..5)") {|id,m|
			meta = m
			''
		}
		f = Runo::Field.instance meta
		assert_equal(
			['1','2','3','4','5'],
			f[:options],
			'Select#initialize should set :options from the range token'
		)

		meta = nil
		Runo::Parser.gsub_scalar("$(foo select ..5)") {|id,m|
			meta = m
			''
		}
		f = Runo::Field.instance meta
		assert_equal(
			['0','1','2','3','4','5'],
			f[:options],
			'Select#initialize should set :options from the range token'
		)

		meta = nil
		Runo::Parser.gsub_scalar("$(foo select 1..)") {|id,m|
			meta = m
			''
		}
		f = Runo::Field.instance meta
		assert_equal(
			nil,
			f[:options],
			'Select#initialize should not refer to the range token if there is no maximum'
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
<select name="" class="select">
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
<select name="" class="select">
	<option>bar</option>
	<option>baz</option>
	<option selected>qux</option>
</select>
_html
			@f.get(:action => :update),
			'Select#get should return proper string'
		)
	end

	def test_get_escape
		@f[:options] = ['foo','<bar>']
		@f.load '<bar>'
		assert_equal(
			'&lt;bar&gt;',
			@f.get,
			'Select#get should escape the special characters'
		)
		assert_equal(
			<<_html.chomp,
<select name="" class="select">
	<option>foo</option>
	<option selected>&lt;bar&gt;</option>
</select>
_html
			@f.get(:action => :update),
			'Select#get should escape the special characters'
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
