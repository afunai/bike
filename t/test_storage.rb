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
			Sofa::Storage.const_get(Sofa['STORAGE']['default']),
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
		sd[:p_size] = 10

		Sofa::Storage.constants.collect {|c| Sofa::Storage.const_get c }.each {|klass|
			next unless klass.is_a?(::Class) && klass.available?

			storage = klass.new sd
			storage.build(
				'20091114_0001' => {'name' => 'bar',  'comment' => 'I am BAR!'},
				'20091115_0001' => {'name' => 'qux',  'comment' => 'Qux! Qux!'},
				'20091114_0002' => {'name' => 'baz',  'comment' => 'BAZ BAZ...'},
				'20091225_0001' => {'name' => 'quux', 'comment' => 'Quux?'},
				'20091225_0002' => {'name' => 'corge','comment' => 'Corge.'},
				'20091226_0001' => {'name' => 'bar',  'comment' => 'I am BAR again!'}
			)

			_test_select(storage)
			_test_sort(storage)
			_test_page(storage)
			_test_val(storage)
			_test_navi(storage)
			_test_last(storage)

			storage.build(
				'00000000_frank' => {'name' => 'fz',  'comment' => 'I am FZ!'},
				'00000000_carl'  => {'name' => 'cz',  'comment' => 'I am CZ!'},
				'00000000_bobby' => {'name' => 'bz',  'comment' => 'I am BZ!'}
			)
			_test_fetch_special_id(storage)

			storage.clear
		}
	end

	def _test_select(storage)
		assert_equal(
			[
				'20091114_0001',
				'20091114_0002',
				'20091115_0001',
				'20091225_0001',
				'20091225_0002',
				'20091226_0001',
			],
			storage.select,
			"#{storage.class}#select should return item ids that match given conds"
		)
		assert_equal(
			['20091114_0001'],
			storage.select(:id => '20091114_0001'),
			"#{storage.class}#select should return item ids that match given conds"
		)
		assert_equal(
			['20091115_0001'],
			storage.select(:d => '20091115'),
			"#{storage.class}#select should return item ids that match given conds"
		)
	end

	def _test_sort(storage)
		assert_equal(
			[
				'20091114_0001',
				'20091114_0002',
				'20091115_0001',
				'20091225_0001',
				'20091225_0002',
				'20091226_0001',
			],
			storage.select(:order => 'd'),
			"#{storage.class}#_sort should sort the item ids returned by _select()"
		)
		assert_equal(
			[
				'20091226_0001',
				'20091225_0002',
				'20091225_0001',
				'20091115_0001',
				'20091114_0002',
				'20091114_0001',
			],
			storage.select(:order => '-d'),
			"#{storage.class}#_sort should sort the item ids returned by _select()"
		)
	end

	def _test_page(storage)
		storage.sd[:p_size] = 4
		assert_equal(
			['20091114_0001','20091114_0002','20091115_0001','20091225_0001'],
			storage.select(:p => 1),
			"#{storage.class}#_page should paginate the item ids returned by _select()"
		)
		assert_equal(
			['20091225_0002','20091226_0001'],
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

	def _test_navi(storage)
		_test_navi_p(storage)
		_test_navi_id(storage)
		_test_navi_d(storage)
		_test_navi_all(storage)

		storage.sd[:p_size] = 10
	end

	def _test_navi_p(storage)
		storage.sd[:p_size] = 2
		assert_equal(
			{
				:prev => {:d => '200912',:p => '1'},
				:sibs => {:p => ['1','2']},
			},
			storage.navi(:d => '200912',:p => '2'),
			"#{storage.class}#navi should return the next conditions for the given conds"
		)
		assert_equal(
			{
				:prev => {:d => '200911',:p => '2'},
				:next => {:d => '200912',:p => '2'},
				:sibs => {:p => ['1','2']},
			},
			storage.navi(:d => '200912',:p => '1'),
			"#{storage.class}#navi should return the next conditions for the given conds"
		)
		assert_equal(
			{
				:prev => {:d => '200911',:p => '1'},
				:next => {:d => '200912',:p => '1'},
				:sibs => {:p => ['1','2']},
			},
			storage.navi(:d => '200911',:p => '2'),
			"#{storage.class}#navi should return the next conditions for the given conds"
		)
		assert_equal(
			{
				:next => {:d => '200911',:p => '2'},
				:sibs => {:p => ['1','2']},
			},
			storage.navi(:d => '200911',:p => '1'),
			"#{storage.class}#navi should return the next conditions for the given conds"
		)
	end

	def _test_navi_id(storage)
		storage.sd[:p_size] = 2
		assert_equal(
			{
				:prev => {:id => '20091225_0002'},
				:sibs => {
					:id => [
						'20091114_0001',
						'20091114_0002',
						'20091115_0001',
						'20091225_0001',
						'20091225_0002',
						'20091226_0001',
					],
				},
			},
			storage.navi(:id => '20091226_0001'),
			"#{storage.class}#navi should return the next conditions for the given conds"
		)

		assert_equal(
			{
				:prev => {:d => '200912',:id => '20091225_0002'},
				:sibs => {:id => ['20091225_0001','20091225_0002','20091226_0001']},
			},
			storage.navi(:d => '200912',:id => '20091226_0001'),
			"#{storage.class}#navi should return the next conditions for the given conds"
		)
		assert_equal(
			{
				:prev => {:d => '200911',:id => '20091115_0001'},
				:next => {:d => '200912',:id => '20091225_0002'},
				:sibs => {:id => ['20091225_0001','20091225_0002','20091226_0001']},
			},
			storage.navi(:d => '200912',:id => '20091225_0001'),
			"#{storage.class}#navi should return the next conditions for the given conds"
		)
		assert_equal(
			{
				:prev => {:d => '200911',:id => '20091114_0002'},
				:next => {:d => '200912',:id => '20091225_0001'},
				:sibs => {:id => ['20091114_0001','20091114_0002','20091115_0001']},
			},
			storage.navi(:d => '200911',:id => '20091115_0001'),
			"#{storage.class}#navi should return the next conditions for the given conds"
		)
		assert_equal(
			{
				:next => {:d => '200911',:id => '20091114_0002'},
				:sibs => {:id => ['20091114_0001','20091114_0002','20091115_0001']},
			},
			storage.navi(:d => '200911',:id => '20091114_0001'),
			"#{storage.class}#navi should return the next conditions for the given conds"
		)
	end

	def _test_navi_d(storage)
		storage.sd[:p_size] = nil
		assert_equal(
			{
				:prev => {:d => '200911'},
				:sibs => {:d => ['200911','200912']},
			},
			storage.navi(:d => '200912'),
			"#{storage.class}#navi should return the next conditions for the given conds"
		)
		assert_equal(
			{
				:next => {:d => '200912'},
				:sibs => {:d => ['200911','200912']},
			},
			storage.navi(:d => '200911'),
			"#{storage.class}#navi should return the next conditions for the given conds"
		)

		assert_equal(
			{
				:next => {:d => '200911',:order => '-d'},
				:sibs => {:d => ['200912','200911']},
			},
			storage.navi(:d => '200912',:order => '-d'),
			"#{storage.class}#navi should return the next conditions for the given conds"
		)
	end

	def _test_navi_all(storage)
		storage.sd[:p_size] = nil
		assert_equal(
			{},
			storage.navi({}),
			"#{storage.class}#navi without conds should return an empty navi"
		)
	end

	def _test_last(storage)
		assert_equal(
			'20091226',
			storage.last(:d,:d => '99999999'),
			"#{storage.class}#last should cast 'the last' conds"
		)
		assert_equal(
			'200912',
			storage.last(:d,:d => '999999'),
			"#{storage.class}#last should cast 'the last' conds"
		)

		assert_equal(
			'20091226_0001',
			storage.last(:id,:id => ['20091114_0001','last']),
			"#{storage.class}#last should cast 'the last' conds"
		)

		storage.sd[:p_size] = 2
		assert_equal(
			'3',
			storage.last(:p,:p => 'last'),
			"#{storage.class}#last should cast 'the last' conds"
		)
		storage.sd[:p_size] = 10
	end

	def _test_fetch_special_id(storage)
		assert_equal(
			[
				'00000000_bobby',
				'00000000_carl',
				'00000000_frank',
			],
			storage.select,
			"#{storage.class}#select should be able to select special ids"
		)
		assert_equal(
			['00000000_carl'],
			storage.select(:id => '00000000_carl'),
			"#{storage.class}#select should be able to select special ids"
		)
		assert_equal(
			['00000000_bobby'],
			storage.select(:id => 'bobby'),
			"#{storage.class}#select should expand short ids"
		)

		assert_equal(
			[
				'00000000_frank',
				'00000000_carl',
				'00000000_bobby',
			],
			storage.select(:order => '-id'),
			"#{storage.class}#select should sort special ids"
		)

		assert_equal(
			{
				:next => {:id => '00000000_carl'},
				:sibs => {:id => ['00000000_bobby','00000000_carl','00000000_frank']},
			},
 			storage.navi(:id => '00000000_bobby'),
			"#{storage.class}#navi should return the next conditions for special ids"
		)
	end

	def test_store
		sd = Sofa::Set::Static::Folder.root.item('t_store','main')

		Sofa::Storage.constants.collect {|c| Sofa::Storage.const_get c }.each {|klass|
			next unless klass.is_a?(::Class) && klass.available?

			storage = klass.new sd
			storage.clear

			id = _test_add(storage)
			_test_update(storage,id)
			_test_delete(storage,id)

			_test_new_id(storage)
			_test_clear(storage)
		}
	end

	def _test_add(storage)
		id = nil
		assert_nothing_raised(
			"#{storage.class}#store should work nicely"
		) {
			id = storage.store(:new_id,{'foo' => 'bar'})
		}
		assert_match(
			Sofa::REX::ID,
			id,
			"#{storage.class}#store should return the id of the created item"
		)
		assert_equal(
			{'foo' => 'bar'},
			storage.val(id),
			"#{storage.class}#store should store the element with the given id"
		)
		id # for other tests
	end

	def _test_update(storage,id)
		storage.store(id,{'foo' => 'updated'})
		assert_equal(
			{'foo' => 'updated'},
			storage.val(id),
			"#{storage.class}#store should store the element with the given id"
		)
	end

	def _test_delete(storage,id)
		assert_nothing_raised(
			"#{storage.class}#delete should work nicely"
		) {
			id = storage.delete(id)
		}
		assert_match(
			Sofa::REX::ID,
			id,
			"#{storage.class}#delete should return the id of the deleted item"
		)
		assert_nil(
			storage.val(id),
			"#{storage.class}#delete should delete the element with the given id"
		)
	end

	def _test_new_id(storage)
		id1 = storage.store(:new_id,{'foo' => 'bar'})
		assert_match(
			Sofa::REX::ID,
			id1,
			"#{storage.class}#new_id should return a unique id for the element"
		)
		id2 = storage.store(:new_id,{'foo' => 'bar'})
		assert_match(
			Sofa::REX::ID,
			id2,
			"#{storage.class}#new_id should return a unique id for the element"
		)
		assert_not_equal(
			id1,
			id2,
			"#{storage.class}#new_id should return a unique id for the element"
		)
	end

	def _test_clear(storage)
		id1 = storage.store(:new_id,{'foo' => 'bar'})
		id2 = storage.store(:new_id,{'foo' => 'bar'})

		storage.clear

		assert_nil(
			storage.val(id1),
			"#{storage.class}#clear should delete all elements"
		)
		assert_nil(
			storage.val(id2),
			"#{storage.class}#clear should delete all elements"
		)
	end

end
