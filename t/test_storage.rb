# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Storage < Test::Unit::TestCase

	def setup
	end

	def teardown
	end

	def test_instance
		sd = Sofa::Set::Static::Folder.root.item('t_select','main')

		assert_instance_of(
			Sofa::Storage.const_get(Sofa::STORAGE['default']),
			sd.storage,
			'Storage.instance should return a File instance when the set is right under the folder'
		)

		child_set = Sofa::Field.instance(
			:klass  => 'set-dynamic',
			:parent => sd
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
		sd = Sofa::Set::Static::Folder.root.item('t_select','main')

		Sofa::Storage.constants.collect {|c| Sofa::Storage.const_get c }.each {|klass|
			next unless klass.available?

			storage = klass.new sd
			storage.build(
				'20091114_0001' => {'name' => 'bar','comment' => 'I am BAR!'},
				'20091114_0003' => {'name' => 'qux','comment' => 'Qux! Qux!'},
				'20091114_0002' => {'name' => 'baz','comment' => 'BAZ BAZ...'}
			)

			_test_select(storage)
			_test_sort(storage)
			_test_page(storage)

			_test_val(storage)
		}
	end

	def _test_select(storage)
		assert_equal(
			['20091114_0001'],
			storage.select(:id => '20091114_0001'),
			"#{storage.class}#select should return item ids that match given conds"
		)
		assert_equal(
			['20091114_0001','20091114_0002','20091114_0003'],
			storage.select,
			"#{storage.class}#select should return item ids that match given conds"
		)
	end

	def _test_sort(storage)
		assert_equal(
			['20091114_0001','20091114_0002','20091114_0003'],
			storage.select(:order => 'd'),
			"#{storage.class}#_sort should sort the item ids returned by _select()"
		)
		assert_equal(
			['20091114_0003','20091114_0002','20091114_0001'],
			storage.select(:order => '-d'),
			"#{storage.class}#_sort should sort the item ids returned by _select()"
		)
	end

	def _test_page(storage)
		storage.sd[:p_size] = 2
		assert_equal(
			['20091114_0001','20091114_0002'],
			storage.select(:p => 1),
			"#{storage.class}#_page should paginate the item ids returned by _select()"
		)
		assert_equal(
			['20091114_0003'],
			storage.select(:p => 2),
			"#{storage.class}#_page should paginate the item ids returned by _select()"
		)
		assert_equal(
			[],
			storage.select(:p => 3),
			"#{storage.class}#_page should return an empty list if the page does not exist"
		)
		storage.sd[:p_size] = 10
	end

	def _test_val(storage)
		assert_equal(
			{'name' => 'baz','comment' => 'BAZ BAZ...'},
			storage.val('20091114_0002'),
			"#{storage.class}#val should return the item value"
		)
		assert_nil(
			storage.val('non-existent'),
			"#{storage.class}#val should return nil when there is no item"
		)
		assert_nil(
			storage.val(''),
			"#{storage.class}#val should return nil when there is no item"
		)
	end

	def test_store
		sd = Sofa::Set::Static::Folder.root.item('t_store','main')

		Sofa::Storage.constants.collect {|c| Sofa::Storage.const_get c }.each {|klass|
			next unless klass.available?

			storage = klass.new sd
			storage.clear
		}
	end

def ptest_p
	puts Sofa::Set::Static::Folder.root.item('t_select').get :conds => {}
end

end
