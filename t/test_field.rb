# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Field::Foo < Sofa::Field
	class Bar < Sofa::Field
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
			Sofa::Field::Foo::Bar,
			@f,
			'Field#instance should return an instance of the class specified by :klass'
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
	end

end
