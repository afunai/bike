# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class Runo::Foo < Runo::Field
	DEFAULT_META = {:foo => 'foo foo'}
	class Bar < Runo::Field
		def _g_test(arg)
			'just a test.'
		end
	end
end

class TC_Field < Test::Unit::TestCase

	def setup
		@f = Runo::Field.instance(
			:klass   => 'foo-bar',
			:baz     => 1234,
			:default => 'bar bar'
		)
	end

	def teardown
	end

	def test_instance
		assert_instance_of(
			Runo::Foo::Bar,
			@f,
			'Field#instance should return an instance of the class specified by :klass'
		)
	end

	def test_wrong_instance
		assert_nil(
			Runo::Field.instance(:klass => 'set'),
			'Field#instance should not return an instance of other than Field'
		)
		assert_nil(
			Runo::Field.instance(:klass => 'storage'),
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

	def test_meta_name
		item = Runo::Set::Static::Folder.root.item('foo','bar','main')
		assert_equal(
			'main',
			item[:name],
			'Field#[:name] should return the path name from the nearest folder'
		)
		item = Runo::Set::Static::Folder.root.item('foo','bar')
		assert_equal(
			'bar',
			item[:name],
			'Field#[:name] should return the path name from the nearest folder'
		)
	end

	def test_meta_full_name
		item = Runo::Set::Static::Folder.root.item('foo','bar','main')
		assert_equal(
			'-foo-bar-main',
			item[:full_name],
			'Field#[:full_name] should return the path name from the root folder'
		)
		item = Runo::Set::Static::Folder.root.item('foo','bar')
		assert_equal(
			'-foo-bar',
			item[:full_name],
			'Field#[:full_name] should return the path name from the root folder'
		)
	end

	def test_meta_short_name
		item = Runo::Set::Static::Folder.root.item(
			'foo','bar','main','20091120_0001','replies','20091208_0001','reply'
		)

		Runo.current[:base] = nil
		assert_equal(
			'reply',
			item[:short_name],
			'Field#[:short_name] should return [:id] if no base SD is defined'
		)

		Runo.current[:base] = Runo::Set::Static::Folder.root.item('foo','bar','main')
		assert_equal(
			'20091120_0001-replies-20091208_0001-reply',
			item[:short_name],
			'Field#[:short_name] should return the path name from the base SD'
		)

		Runo.current[:base] = Runo::Set::Static::Folder.root.item(
			'foo','bar','main','20091120_0001','replies'
		)
		assert_equal(
			'20091208_0001-reply',
			item[:short_name],
			'Field#[:short_name] should return the path name from the base SD'
		)

		Runo.current[:base] = Runo::Set::Static::Folder.root.item('foo','bar','main')
		assert_equal(
			'',
			Runo::Set::Static::Folder.root.item('foo','bar','main')[:short_name],
			'Field#[:short_name] should return empty string for the base SD itself'
		)
	end

	def test_meta_sd
		sd = Runo::Set::Static::Folder.root.item('foo','bar','main')
		assert_equal(
			sd,
			sd[:sd],
			'Field#[:sd] should return the nearest set_dynamic'
		)
		assert_equal(
			sd,
			sd.item('20091120_0001')[:sd],
			'Field#[:sd] should return the nearest set_dynamic'
		)
		assert_equal(
			sd,
			sd.item('20091120_0001','name')[:sd],
			'Field#[:sd] should return the nearest set_dynamic'
		)
		assert_nil(
			Runo::Set::Static::Folder.root[:sd],
			'Field#[:sd] should return nil if there is no set_dynamic in the ancestors'
		)
	end

	def test_meta_client
		Runo.client = 'frank'
		assert_equal(
			'frank',
			Runo::Field.new[:client],
			'Field#[:client] should return the client of the current thread'
		)
	end

	def test_empty?
		@f.load 'foo'
		assert(
			!@f.empty?,
			'Field#empty? should return false if the field has a value'
		)

		@f.load nil
		assert(
			@f.empty?,
			'Field#empty? should return true if the field has no value'
		)
	end

	def test_default_meta
		f = Runo::Field.instance(:klass => 'foo')
		assert_equal(
			'foo foo',
			f[:foo],
			'Field#[] should look for the default value in DEFAULT_META'
		)

		f = Runo::Field.instance(:klass => 'foo',:foo => 'bar')
		assert_equal(
			'bar',
			f[:foo],
			'Field.DEFAULT_META should be eclipsed by @meta'
		)

		f = Runo::Field.instance(:klass => 'foo')
		def f.meta_foo
			'abc'
		end
		assert_equal(
			'abc',
			f[:foo],
			'Field.DEFAULT_META should be eclipsed by meta_*()'
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
			'Field#get should relay the result of _g_*()'
		)

		@f[:tmpl_foo] = 'foo foo'
		assert_equal(
			'hello',
			@f.get(:action => :foo),
			'Field#get should not use [:tmpl_*]'
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
			@f.action,
			'Field#post should set @action'
		)

		@f.commit
		assert_equal(
			:create,
			@f.result,
			'Field#commit should set @result'
		)

		@f.post(:update,111)
		assert_nil(
			@f.result,
			'Field#post should reset @result'
		)
		assert_equal(
			111,
			@f.val,
			'Field#post should set @val'
		)
		assert_equal(
			:update,
			@f.action,
			'Field#post should set @action'
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
			@f.action,
			'Field#load_default should not set @action'
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
			@f.action,
			'Field#load should not set @action'
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
			@f.action,
			'Field#create should set @action'
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
			@f.action,
			'Field#update should set @action'
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
			@f.action,
			'Field#delete should set @action'
		)
	end

end
