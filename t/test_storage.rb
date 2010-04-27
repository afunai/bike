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

			storage.clear # so far, storage with raw values can not be built at once.
			storage.store('20100406_0001',"\x01\x02\x03",'jpg')
			_test_val_raw(storage)

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

	def _test_val_raw(storage)
		assert_equal(
			"\x01\x02\x03",
			storage.val('20100406_0001'),
			"#{storage.class}#val should return the raw value unless the value is not a hash"
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
			_test_rename(storage)
			_test_clear(storage)

			id = _test_add_raw(storage)
			_test_update_raw(storage,id)
			_test_delete_raw(storage,id)
			_test_clear_raw(storage)
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
			"#{storage.class}#new_id should return a valid id for the element"
		)

		id2 = storage.store(:new_id,{'foo' => 'bar'})
		assert_match(
			Sofa::REX::ID,
			id2,
			"#{storage.class}#new_id should return a valid id for the element"
		)
		assert_not_equal(
			id1,
			id2,
			"#{storage.class}#new_id should return a unique id for the element"
		)

		id3 = storage.store(:new_id,{'foo' => 'bar','_id' => 'carl'})
		assert_match(
			Sofa::REX::ID,
			id3,
			"#{storage.class}#new_id should return a valid id for the element"
		)
		assert_equal(
			'00000000_carl',
			id3,
			"#{storage.class}#new_id should refer to val['_id'] if available"
		)

		id4 = storage.store(:new_id,{'foo' => 'duplicated!','_id' => 'carl'})
		assert_nil(
			id4,
			"#{storage.class}#store should not create an item with a duplicate id"
		)

		id5 = storage.store(
			:new_id,
			{'_timestamp' => {'published' => Time.local(1981,4,26)}}
		)
		assert_match(
			Sofa::REX::ID,
			id5,
			"#{storage.class}#new_id should return a valid id for the element"
		)
		assert_equal(
			'19810426_0001',
			id5,
			"#{storage.class}#new_id should refer to val['_timestamp'] if available"
		)
	end

	def _test_rename(storage)
		orig_id = storage.store(:new_id,{'foo' => 'bar'})
		file_id = storage.store("#{orig_id}-file",'i am file.','bin')
		new_id  = storage.store(orig_id,{'_id' => 'renamed'})

		assert_not_equal(
			orig_id,
			new_id,
			"#{storage.class}#store should rename the element given a different id / timestamp"
		)
		assert_equal(
			{'_id' => 'renamed'},
			storage.val(new_id),
			"#{storage.class}#store should rename the element given a different id / timestamp"
		)
		assert_equal(
			'i am file.',
			storage.val("#{new_id}-file"),
			"#{storage.class}#store should rename the descendant elements"
		)
		assert_nil(
			storage.val(orig_id),
			"#{storage.class}#store should rename the element given a different id / timestamp"
		)
		assert_nil(
			storage.val(file_id),
			"#{storage.class}#store should rename the descendant elements"
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

	def _test_add_raw(storage)
		id = nil
		assert_nothing_raised(
			"#{storage.class}#store should store raw value nicely"
		) {
			id = storage.store(:new_id,"\x01\x02\x03",'jpg')
		}
		assert_equal(
			"\x01\x02\x03",
			storage.val(id),
			"#{storage.class}#store should store the raw file with the given id"
		)
		id # for other tests
	end

	def _test_update_raw(storage,id)
		storage.store(id,"\x04\x05\x06",'png')
		assert_equal(
			"\x04\x05\x06",
			storage.val(id),
			"#{storage.class}#store should overwrite a file with the same id"
		)
	end

	def _test_delete_raw(storage,id)
		assert_nothing_raised(
			"#{storage.class}#delete should work nicely on raw files"
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

	def _test_clear_raw(storage)
		id1 = storage.store(:new_id,"\x03\x02\x01",'jpg')
		id2 = storage.store(:new_id,"\x03\x02\x01",'png')

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

	def test_cast_d
		sd = Sofa::Set::Dynamic.new(
			:klass => 'set-dynamic'
		).load(
			'20091128_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091130_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091201_0001' => {'name' => 'frank','comment' => 'bar'}
		)
		storage = sd.storage

		assert_equal(
			{:d => '20100131'},
			storage.send(
				:_cast,
				{:d => ['20100131']}
			),
			'Storage#_cast should cast conds[:d] as a string'
		)
		assert_equal(
			{:d => nil},
			storage.send(
				:_cast,
				{:d => '30100131'}
			),
			'Storage#_cast should bang malformed conds[:d]'
		)
		assert_equal(
			{:d => '20091201'},
			storage.send(
				:_cast,
				{:d => '99999999'}
			),
			"Storage#_cast should cast 'the last' conds"
		)
		assert_equal(
			{:d => '200912'},
			storage.send(
				:_cast,
				{:d => '999999'}
			),
			"Storage#_cast should cast 'the last' conds"
		)
	end

	def test_cast_id
		sd = Sofa::Set::Dynamic.new(
			:klass => 'set-dynamic'
		).load(
			'20091128_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091130_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091226_0001' => {'name' => 'frank','comment' => 'bar'}
		)
		storage = sd.storage

		assert_equal(
			{:id => ['20091226_0001']},
			storage.send(
				:_cast,
				{:id => '20091226_0001'}
			),
			'Storage#_cast should cast conds[:id] as an array'
		)
		assert_equal(
			{:id => ['20091226_0001']},
			storage.send(
				:_cast,
				{:id => ['20091226_0001','../i_am_evil']}
			),
			'Storage#_cast should bang malformed conds[:id]'
		)
		assert_equal(
			{:id => ['20091114_0001','20091226_0001']},
			storage.send(
				:_cast,
				{:id => ['20091114_0001','last']}
			),
			"Storage#_cast should cast 'the last' conds"
		)
	end

	def test_cast_p
		sd = Sofa::Set::Dynamic.new(
			:klass => 'set-dynamic'
		).load(
			'20091128_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091130_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091226_0001' => {'name' => 'frank','comment' => 'bar'},
			'20100207_0001' => {'name' => 'frank','comment' => 'bar'},
			'20100207_0002' => {'name' => 'frank','comment' => 'bar'}
		)
		storage = sd.storage

		sd[:p_size] = 2
		assert_equal(
			{:p => '123'},
			storage.send(
				:_cast,
				{:p => ['123']}
			),
			'Storage#_cast should cast conds[:p] as a string'
		)
		assert_equal(
			{:p => nil},
			storage.send(
				:_cast,
				{:p => 'i am evil'}
			),
			'Storage#_cast should bang malformed conds[:p]'
		)
		assert_equal(
			{:p => '3'},
			storage.send(
				:_cast,
				{:p => 'last'}
			),
			"Storage#_cast should cast 'the last' conds"
		)
	end

end
