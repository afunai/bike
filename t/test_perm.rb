# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Perm < Test::Unit::TestCase

	def setup
	end

	def teardown
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

def ptest_role
	Sofa.session
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
