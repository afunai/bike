# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Storage < Test::Unit::TestCase

	def setup
		@list = Sofa::Field.instance(
			:klass  => 'list',
			:id     => 'main',
			:parent => Sofa::Field.instance(:id => 'foo',:klass => 'set-folder')
		)
	end

	def teardown
	end

	def test_file_instance
		assert_instance_of(
			Sofa::Storage::File,
			@list.storage,
			'Storage.instance should return a File instance when the list is right under the folder'
		)

		child_list = Sofa::Field.instance(
			:klass  => 'list',
			:parent => @list
		)
		assert_instance_of(
			Sofa::Storage::Temp,
			child_list.storage,
			'Storage.instance should return a Temp when the list is not a child of the folder'
		)

		orphan_list = Sofa::Field.instance(
			:klass  => 'list'
		)
		assert_instance_of(
			Sofa::Storage::Temp,
			orphan_list.storage,
			'Storage.instance should return a Temp when the list is a direct child of the folder'
		)
	end

	def test_select
		list = Sofa::Field.instance :klass => 'list'
		list.load(
			'1234' => {'foo' => 'bar'},
			'1235' => {'foo' => 'baz'}
		)
		assert_equal(
			['1234'],
			list.storage.select(:id => '1234'),
			'Storage#select should return item ids that match given conds'
		)
		assert_equal(
			['1234','1235'],
			list.storage.select,
			'Storage#select should return item ids that match given conds'
		)
	end

end
