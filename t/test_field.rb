# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Foo < Sofa::Field
	class Bar < Sofa::Field
		def _g_test(arg)
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

	def test_name
		item = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		assert_equal(
			'main',
			item[:name],
			'Field#[:name] should return the path name from the nearest folder'
		)
		item = Sofa::Set::Static::Folder.root.item('foo','bar')
		assert_equal(
			'bar',
			item[:name],
			'Field#[:name] should return the path name from the nearest folder'
		)
	end

	def test_full_name
		item = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		assert_equal(
			'-foo-bar-main',
			item[:full_name],
			'Field#[:full_name] should return the path name from the root folder'
		)
		item = Sofa::Set::Static::Folder.root.item('foo','bar')
		assert_equal(
			'-foo-bar',
			item[:full_name],
			'Field#[:full_name] should return the path name from the root folder'
		)
	end

	def test_short_name
		item = Sofa::Set::Static::Folder.root.item(
			'foo','bar','main','20091120_0001','replies','20091208_0001','reply'
		)

		Sofa.current[:base] = nil
		assert_equal(
			'reply',
			item[:short_name],
			'Field#[:short_name] should return [:id] if no base SD is defined'
		)

		Sofa.current[:base] = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		assert_equal(
			'20091120_0001-replies-20091208_0001-reply',
			item[:short_name],
			'Field#[:short_name] should return the path name from the base SD'
		)

		Sofa.current[:base] = Sofa::Set::Static::Folder.root.item(
			'foo','bar','main','20091120_0001','replies'
		)
		assert_equal(
			'20091208_0001-reply',
			item[:short_name],
			'Field#[:short_name] should return the path name from the base SD'
		)

		Sofa.current[:base] = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		assert_equal(
			'',
			Sofa::Set::Static::Folder.root.item('foo','bar','main')[:short_name],
			'Field#[:short_name] should return empty string for the base SD itself'
		)
	end

	def test_sd
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		assert_equal(
			sd,
			sd[:sd],
			'Field#[:workflow] should return the nearest set_dynamic'
		)
		assert_equal(
			sd,
			sd.item('20091120_0001')[:sd],
			'Field#[:workflow] should return the nearest set_dynamic'
		)
		assert_equal(
			sd,
			sd.item('20091120_0001','name')[:sd],
			'Field#[:workflow] should return the nearest set_dynamic'
		)
		assert_nil(
			Sofa::Set::Static::Folder.root[:sd],
			'Field#[:workflow] should return nil if there is no set_dynamic in the ancestors'
		)
	end

	def test_path
		item = Sofa::Set::Static::Folder.root.item('foo','main')
		Sofa.current[:base] = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		assert_equal(
			'/foo/bar/main',
			item[:base_path],
			'Field#[:base_path] should return the path name of the base SD'
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

		@f.post(:update,111)
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
