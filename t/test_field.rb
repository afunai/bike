# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Foo < Sofa::Field
	class Bar < Sofa::Field
		def _get_test(arg)
			'just a test.'
		end
	end
end

class TC_Field < Test::Unit::TestCase

	def setup
		@f = Sofa::Field.instance(
			:klass   => 'foo-bar',
			:baz     => 1234,
			:default => 'bar bar'
		)
	end

	def teardown
	end

	def test_instance
		assert_instance_of(
			Sofa::Foo::Bar,
			@f,
			'Field#instance should return an instance of the class specified by :klass'
		)
	end

	def test_wrong_instance
		assert_nil(
			Sofa::Field.instance(:klass => 'set'),
			'Field#instance should not return an instance of other than Field'
		)
		assert_nil(
			Sofa::Field.instance(:klass => 'storage'),
			'Field#instance should not return an instance of other than Field'
		)
	end

	def test_meta
		assert_equal(
			{:klass => 'foo-bar',:baz => 1234,:default => 'bar bar'},
			@f.instance_variable_get(:@meta),
			'Field#instance should load @meta of the instance'
		)
		assert_nothing_raised('Field#[]= should set the item in @meta') {
			@f[:baz] = 'new value'
		}
		assert_equal(
			'new value',
			@f[:baz],
			'Field#[] should get the item in @meta'
		)
	end

	def test_post
		@f.post(:create,999)
		assert_equal(
			999,
			@f.val,
			'Field#post should set @val'
		)
		assert_equal(
			:create,
			@f.queue,
			'Field#post should set @queue'
		)

		@f.post(:update,111)
		assert_equal(
			111,
			@f.val,
			'Field#post should set @val'
		)
		assert_equal(
			:update,
			@f.queue,
			'Field#post should set @queue'
		)
	end

	def test_load_default
		@f.load_default
		assert_equal(
			'bar bar',
			@f.val,
			'Field#load_default should set @val to [:default]'
		)
		assert_nil(
			@f.queue,
			'Field#load_default should not set @queue'
		)
	end

	def test_load
		@f.load 'baz baz'
		assert_equal(
			'baz baz',
			@f.val,
			'Field#load should set @val'
		)
		assert_nil(
			@f.queue,
			'Field#load should not set @queue'
		)
	end

	def test_create
		@f.create 'baz baz'
		assert_equal(
			'baz baz',
			@f.val,
			'Field#create should set @val'
		)
		assert_equal(
			:create,
			@f.queue,
			'Field#create should set @queue'
		)
	end

	def test_update
		@f.update 'baz baz'
		assert_equal(
			'baz baz',
			@f.val,
			'Field#update should set @val'
		)
		assert_equal(
			:update,
			@f.queue,
			'Field#update should set @queue'
		)
	end

	def test_delete
		@f.delete
		assert_equal(
			nil,
			@f.val,
			'Field#delete should not set @val'
		)
		assert_equal(
			:delete,
			@f.queue,
			'Field#delete should set @queue'
		)
		assert(
			@f.deleted?,
			'Field#delete should set the result of deleted?() to true'
		)
	end

	def test_get
		@f.instance_variable_set(:@val,'hello')
		assert_equal(
			'hello',
			@f.get,
			'Field#get should return @val by default'
		)

		assert_equal(
			'just a test.',
			@f.get(:action => :test),
			'Field#get should relay the result of _get_*()'
		)

		@f[:tmpl_foo] = 'foo foo'
		assert_equal(
			'foo foo',
			@f.get(:action => :foo),
			'Field#get should look for [:tmpl_*]'
		)
	end

	def test_get_by_tmpl
		@f.instance_variable_set(:@val,'hello')
		@f[:tmpl_foo] = 'foo $() foo'
		assert_equal(
			'foo hello foo',
			@f.get(:action => :foo),
			'Field#_get_by_tmpl should replace %() with @val'
		)

		@f[:tmpl_foo] = 'foo @(baz) foo'
		assert_equal(
			'foo 1234 foo',
			@f.get(:action => :foo),
			'Field#_get_by_tmpl should replace @(...) with @meta[...]'
		)
	end

end