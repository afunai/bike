# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Storage < Test::Unit::TestCase

	def setup
		@sd = Sofa::Field.instance(
			:klass  => 'set-dynamic',
			:id     => 'main',
			:parent => Sofa::Field.instance(:id => 'foo',:klass => 'set-static-folder')
		)
	end

	def teardown
	end

	def test_instance
		assert_instance_of(
			Sofa::Storage.const_get(Sofa::STORAGE[:klass]),
			@sd.storage,
			'Storage.instance should return a File instance when the set is right under the folder'
		)

		child_set = Sofa::Field.instance(
			:klass  => 'set-dynamic',
			:parent => @sd
		)
		assert_instance_of(
			Sofa::Storage::Temp,
			child_set.storage,
			'Storage.instance should return a Temp when the set is not a child of the folder'
		)

		orphan_set = Sofa::Field.instance(
			:klass  => 'set-dynamic'
		)
		assert_instance_of(
			Sofa::Storage::Temp,
			orphan_set.storage,
			'Storage.instance should return a Temp when the set is a direct child of the folder'
		)
	end

	def test_fetch
		sd = Sofa::Field.instance :klass => 'set-dynamic'
		sd.load(
			'1234' => {'foo' => 'bar'},
			'1236' => {'foo' => 'qux'},
			'1235' => {'foo' => 'baz'}
		) if sd.storage.respond_to? :load
		_test_select(sd)
		_test_sort(sd)
		_test_page(sd)
	end

	def _test_select(sd)
		assert_equal(
			['1234'],
			sd.storage.select(:id => '1234'),
			'Storage#select should return item ids that match given conds'
		)
		assert_equal(
			['1234','1235','1236'],
			sd.storage.select,
			'Storage#select should return item ids that match given conds'
		)
	end

	def _test_sort(sd)
		assert_equal(
			['1234','1235','1236'],
			sd.storage.select(:order => 'd'),
			'Storage#_sort should sort the item ids returned by _select()'
		)
		assert_equal(
			['1236','1235','1234'],
			sd.storage.select(:order => '-d'),
			'Storage#_sort should sort the item ids returned by _select()'
		)
	end

	def _test_page(sd)
		sd[:p_size] = 2
		assert_equal(
			['1234','1235'],
			sd.storage.select(:p => 1),
			'Storage#_page should paginate the item ids returned by _select()'
		)
		assert_equal(
			['1236'],
			sd.storage.select(:p => 2),
			'Storage#_page should paginate the item ids returned by _select()'
		)
		assert_equal(
			[],
			sd.storage.select(:p => 3),
			'Storage#_page should return an empty list if the page does not exist'
		)
	end

end
