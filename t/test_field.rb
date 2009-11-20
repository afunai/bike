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

	def test_owner
		assert_equal(
			'root',
			Sofa::Set::Static::Folder.root[:owner],
			"Field#[:owner] should return 'root' for the root folder"
		)
		assert_equal(
			'frank',
			Sofa::Set::Static::Folder.root.item('foo')[:owner],
			'Field#[:owner] should return @meta[:owner] if available'
		)
		assert_equal(
			'frank',
			Sofa::Set::Static::Folder.root.item('foo','main')[:owner],
			'Field#[:owner] should return parent[:owner] if @meta[:owner] is nil'
		)
		assert_equal(
			'frank',
			Sofa::Set::Static::Folder.root.item('foo','main','20091120_0001')[:owner],
			'Field#[:owner] should return parent[:owner] if @meta[:owner] is nil'
		)

		assert_equal(
			'frank',
			Sofa::Set::Static::Folder.root.item('foo','bar')[:owner],
			'Field#[:owner] should return parent[:owner] if @meta[:owner] is nil'
		)
		assert_equal(
			'frank',
			Sofa::Set::Static::Folder.root.item('foo','bar','main')[:owner],
			'Field#[:owner] should return parent[:owner] if @meta[:owner] is nil'
		)
		assert_equal(
			'carl',
			Sofa::Set::Static::Folder.root.item('foo','bar','main','20091120_0001')[:owner],
			'Field#[:owner] should return @meta[:owner] if available'
		)
		assert_equal(
			'carl',
			Sofa::Set::Static::Folder.root.item('foo','bar','main','20091120_0001','name')[:owner],
			'Field#[:owner] should return parent[:owner] if @meta[:owner] is nil'
		)
	end

	def test_owners
		assert_equal(
			['root'],
			Sofa::Set::Static::Folder.root[:owners],
			"Field#[:owners] should return ['root'] for the root folder"
		)
		assert_equal(
			['root','frank'],
			Sofa::Set::Static::Folder.root.item('foo')[:owners],
			'Field#[:owners] should return all the owners of the ancestor fields'
		)
		assert_equal(
			['root','frank'],
			Sofa::Set::Static::Folder.root.item('foo','main')[:owners],
			'Field#[:owners] should return all the owners of the ancestor fields'
		)
		assert_equal(
			['root','frank','carl'],
			Sofa::Set::Static::Folder.root.item('foo','bar','main','20091120_0001')[:owners],
			'Field#[:owners] should return all the owners of the ancestor fields'
		)
	end

	def test_admins
		assert_equal(
			[],
			Sofa::Set::Static::Folder.root[:admins],
			"Field#[:admins] should return [] for the root folder"
		)
		assert_equal(
			['root'],
			Sofa::Set::Static::Folder.root.item('foo')[:admins],
			'Field#[:admins] should return @meta[:admins] if available'
		)
		assert_equal(
			['root','frank'],
			Sofa::Set::Static::Folder.root.item('foo','main')[:admins],
			'Field#[:admins] should return parent[:admins] if @meta[:admins] is nil'
		)
		assert_equal(
			['root','frank'],
			Sofa::Set::Static::Folder.root.item('foo','main','20091120_0001')[:admins],
			'Field#[:admins] should return parent[:admins] if @meta[:admins] is nil'
		)

		assert_equal(
			['root','frank'],
			Sofa::Set::Static::Folder.root.item('foo','bar')[:admins],
			'Field#[:admins] should return parent[:admins] if @meta[:admins] is nil'
		)
		assert_equal(
			['root','frank'],
			Sofa::Set::Static::Folder.root.item('foo','bar','main')[:admins],
			'Field#[:admins] should return parent[:admins] if @meta[:admins] is nil'
		)
		assert_equal(
			['root','frank'],
			Sofa::Set::Static::Folder.root.item('foo','bar','main','20091120_0001')[:admins],
			'Field#[:admins] should return @meta[:admins] if available'
		)
		assert_equal(
			['root','frank'],
			Sofa::Set::Static::Folder.root.item('foo','bar','main','20091120_0001','name')[:admins],
			'Field#[:admins] should return @meta[:admins] if available'
		)
	end

	def test_group
		assert_equal(
			[],
			Sofa::Set::Static::Folder.root[:group],
			"Field#[:group] should return [] for the root folder"
		)
		assert_equal(
			['roy','jim'],
			Sofa::Set::Static::Folder.root.item('foo')[:group],
			'Field#[:group] should return @meta[:group] if available'
		)
		assert_equal(
			['roy','jim'],
			Sofa::Set::Static::Folder.root.item('foo','main')[:group],
			'Field#[:group] should return @meta[:group] of the nearest folder'
		)
		assert_equal(
			['roy','jim'],
			Sofa::Set::Static::Folder.root.item('foo','main','20091120_0001')[:group],
			'Field#[:group] should return @meta[:group] of the nearest folder'
		)

		assert_equal(
			['don'],
			Sofa::Set::Static::Folder.root.item('foo','bar')[:group],
			'Field#[:group] should return @meta[:group] if available'
		)
		assert_equal(
			['don'],
			Sofa::Set::Static::Folder.root.item('foo','bar','main')[:group],
			'Field#[:group] should return @meta[:group] of the nearest folder'
		)
	end

end
