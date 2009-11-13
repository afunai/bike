# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Storage < Test::Unit::TestCase

	def setup
		@list = Sofa::Field.instance(
			:klass  => 'set-dynamic',
			:id     => 'main',
			:parent => Sofa::Field.instance(:id => 'foo',:klass => 'set-static-folder')
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
			:klass  => 'set-dynamic',
			:parent => @list
		)
		assert_instance_of(
			Sofa::Storage::Temp,
			child_list.storage,
			'Storage.instance should return a Temp when the list is not a child of the folder'
		)

		orphan_list = Sofa::Field.instance(
			:klass  => 'set-dynamic'
		)
		assert_instance_of(
			Sofa::Storage::Temp,
			orphan_list.storage,
			'Storage.instance should return a Temp when the list is a direct child of the folder'
		)
	end

	def test_select
		list = Sofa::Field.instance :klass => 'set-dynamic'
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

	def test_sort
		list = Sofa::Field.instance :klass => 'set-dynamic'
		list.load(
			'1234' => {'foo' => 'bar'},
			'1236' => {'foo' => 'qux'},
			'1235' => {'foo' => 'baz'}
		)
		assert_equal(
			['1236','1235','1234'],
			list.storage.select(:order => '-d'),
			'Storage#_sort should sort the item ids returned by _select()'
		)
	end

	def test_page
		list = Sofa::Field.instance :klass => 'set-dynamic'
		list.load(
			'1234' => {'foo' => 'bar'},
			'1236' => {'foo' => 'qux'},
			'1235' => {'foo' => 'baz'}
		)
		list[:p_size] = 2
		assert_equal(
			['1234','1235'],
			list.storage.select(:p => 1),
			'Storage#_page should paginate the item ids returned by _select()'
		)
		assert_equal(
			['1236'],
			list.storage.select(:p => 2),
			'Storage#_page should paginate the item ids returned by _select()'
		)
		assert_equal(
			[],
			list.storage.select(:p => 3),
			'Storage#_page should return an empty list if the page does not exist'
		)
	end

end
