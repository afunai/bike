# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Password < Test::Unit::TestCase

	def setup
		@f = Sofa::Field.instance(
			:klass   => 'password',
			:default => 'secret'
		)
	end

	def teardown
	end

	def test_get
		@f.instance_variable_set(:@val,'hello')

		assert_equal(
			'xxxxx',
			@f.get(:action => :read),
			'Field::Password#get should not return anything other than a dummy string'
		)

		assert_match(
			/<input/,
			@f.get(:action => :create),
			'Field::Password#get(:action => :create) should return an empty form'
		)
		assert_match(
			/<input/,
			@f.get(:action => :update),
			'Field::Password#get(:action => :update) should return an empty form'
		)
	end

	def test_load_default
		@f.load_default
		assert_nil(
			@f.val,
			'Field::Password#load_default should not load any value'
		)
	end

	def test_load
		@f.load 'foobar'
		assert_equal(
			'foobar',
			@f.val,
			'Field::Password#load should not alter the loaded value'
		)
	end

	def test_create
		@f.create 'foobar'
		assert_not_equal(
			'foobar',
			@f.val,
			'Field::Password#create should store the value as a crypted string'
		)
	end

	def test_update
		@f.load 'original'

		@f.update nil
		assert_equal(
			'original',
			@f.val,
			'Field::Password#update should not update with nil'
		)

		@f.update ''
		assert_equal(
			'original',
			@f.val,
			'Field::Password#update should not update with an empty string'
		)

		@f.update 'updated'
		assert_not_equal(
			'original',
			@f.val,
			'Field::Password#update should update with a non-empty string'
		)
		assert_not_equal(
			'updated',
			@f.val,
			'Field::Password#update should store the value as a crypted string'
		)
	end
end
