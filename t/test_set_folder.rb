# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Set_Folder < Test::Unit::TestCase

	def setup
	end

	def teardown
	end

	def test_initialize
		folder = Sofa::Field::Set::Folder.new(:id => 'foo',:parent => nil)
		assert_match(
			/^<html>/,
			folder[:html],
			'Folder#initialize should load [:html] from [:dir]/_.html'
		)
		assert_instance_of(
			Sofa::Field::List,
			folder.item('main'),
			'Folder#initialize should load the items according to [:html]'
		)
	end

	def test_default_items
		folder = Sofa::Field::Set::Folder.new(:id => 'foo',:parent => nil)
		assert_instance_of(
			Sofa::Field::Text,
			folder.item('_label'),
			'Folder#initialize should always load the default items'
		)
		assert_equal(
			'Foo Folder',
			folder.val('_label'),
			'Folder#initialize should load the val from [:dir].yaml'
		)
		assert_equal(
			'frank',
			folder.val('_owner'),
			'Folder#initialize should load the val from [:dir].yaml'
		)
	end

	def test_child_folder
		folder = Sofa::Field::Set::Folder.new(:id => 'foo',:parent => nil)
		child  = folder.item('bar')
		assert_instance_of(
			Sofa::Field::Set::Folder,
			child,
			'Folder#item should look the real directory for the child item'
		)
		assert_equal(
			'Bar Folder',
			child.val('_label'),
			'Folder#initialize should load the val from [:dir].yaml'
		)
		assert_equal(
			'frank',
			child.val('_owner'),
			'Folder#initialize should inherit the val of default items from [:parent]'
		)
	end

end
