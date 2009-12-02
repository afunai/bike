# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Set_Dynamic < Test::Unit::TestCase

	def setup
		@sd = Sofa::Set::Dynamic.new(
			:id        => 'main',
			:klass     => 'set-dynamic',
			:workflow  => 'blog',
			:group     => ['roy','don'],
			:tmpl      => <<'_tmpl',
<ul id="foo" class="sofa-blog">
$()</ul>
_tmpl
			:item_html => <<'_html'
	<li>name:(text 32 :'nobody'): comment:(text 64 :'hi.')</li>
_html
		)
		Sofa.client = 'root'
	end

	def teardown
		Sofa.client = nil
	end

	def test_storage
		assert_kind_of(
			Sofa::Storage,
			@sd.storage,
			'Set::Dynamic#instance should load an apropriate storage for the list'
		)
		assert_instance_of(
			Sofa::Storage::Temp,
			@sd.storage,
			'Set::Dynamic#instance should load an apropriate storage for the list'
		)
	end

	def test_item
		@sd.load('1234' => {'name' => 'frank'})
		assert_instance_of(
			Sofa::Set::Static,
			@sd.item('1234'),
			'Set::Dynamic#item should return the child set in the storage'
		)

		assert_nil(
			@sd.item('non-existent'),
			'Set::Dynamic#item should return nil when the item is not in the storage'
		)
		assert_nil(
			@sd.item(''),
			'Set::Dynamic#item should return nil when the item is not in the storage'
		)
	end

	def test_val
		@sd.load(
			'1234' => {'name' => 'frank'},
			'1235' => {'name' => 'carl'}
		)
		assert_equal(
			{
				'1234' => {'name' => 'frank'},
				'1235' => {'name' => 'carl'},
			},
			@sd.val,
			'Set::Dynamic#val without arg should return values of all items in the storage'
		)
		assert_equal(
			{'name' => 'frank'},
			@sd.val('1234'),
			'Set::Dynamic#val with an item id should return the value of the item in the storage'
		)
		assert_nil(
			@sd.val('non-existent'),
			'Set::Dynamic#val with an item id should return nil when the item is not in the storage'
		)
	end

	def test_get
		@sd.load(
			'1234' => {'name' => 'frank','comment' => 'bar'},
			'1235' => {'name' => 'carl', 'comment' => 'baz'}
		)
		assert_equal(
			<<'_html',
<ul id="foo" class="sofa-blog">
	<li>frank: bar</li>
	<li>carl: baz</li>
</ul>
_html
			@sd.get,
			'Set::Dynamic#get should return the html by [:tmpl]'
		)
		assert_equal(
			<<'_html',
<ul id="foo" class="sofa-blog">
	<li>carl: baz</li>
</ul>
_html
			@sd.get(:conds => {:id => '1235'}),
			'Set::Dynamic#get should return the html by [:tmpl]'
		)

		@sd.each {|ss|
			ss.each {|item|
				def item._get_update(arg)
					'moo!'
				end
			}
		}
		assert_equal(
			<<'_html',
<form id="main" method="post" action="">
<ul id="foo" class="sofa-blog">
	<li>moo!: moo!</li>
</ul>
</form>
_html
			@sd.get(:conds => {:id => '1235'},:action => :update),
			'Set::Dynamic#get should return the html by [:tmpl]'
		)
	end

	def test_load_default
	end

	def test_load
		@sd.load('1235' => {'name' => 'carl'})
		assert_equal(
			{'1235' => {'name' => 'carl'}},
			@sd.val,
			'Set::Dynamic#load should load the storage with the given values'
		)
		@sd.load('1234' => {'name' => 'frank'})
		assert_equal(
			{'1234' => {'name' => 'frank'}},
			@sd.val,
			'Set::Dynamic#load should overwrite all values in the storage'
		)
	end

	def test_create
		@sd.create('1235' => {'name' => 'carl'})
		assert_equal(
			{'1235' => {'name' => 'carl'}},
			@sd.val,
			'Set::Dynamic#create should create the storage with the given values'
		)
		@sd.create('1234' => {'name' => 'frank'})
		assert_equal(
			{'1234' => {'name' => 'frank'}},
			@sd.val,
			'Set::Dynamic#create should overwrite all values in the storage'
		)
	end

	def test_update
		@sd.load(
			'20091122_1234' => {'name' => 'frank','comment' => 'bar'},
			'20091122_1235' => {'name' => 'carl', 'comment' => 'baz'}
		)
		s = @sd.storage
		def s.new_id
			'new!'
		end

		# update an item
		@sd.update('20091122_1234' => {'comment' => 'qux'})
		assert_equal(
			{'name' => 'frank','comment' => 'qux'},
			@sd.item('20091122_1234').val,
			'Set::Dynamic#update should update the values of the item instance'
		)
		assert_equal(
			:update,
			@sd.item('20091122_1234').action,
			'Set::Dynamic#update should set a proper action on the item'
		)
		assert_equal(
			nil,
			@sd.item('20091122_1234','name').action,
			'Set::Dynamic#update should set a proper action on the item'
		)
		assert_equal(
			:update,
			@sd.item('20091122_1234','comment').action,
			'Set::Dynamic#update should set a proper action on the item'
		)

		# create an item
		@sd.update('_1236' => {'name' => 'roy'})
		assert_equal(
			{'name' => 'roy','comment' => 'hi.'},
			@sd.item('_1236').val,
			'Set::Dynamic#update should update the values of the item instance'
		)
		assert_equal(
			:create,
			@sd.item('_1236').action,
			'Set::Dynamic#update should set a proper action on the item'
		)
		assert_equal(
			:create,
			@sd.item('_1236','name').action,
			'Set::Dynamic#update should set a proper action on the item'
		)
		assert_equal(
			nil,
			@sd.item('_1236','comment').action,
			'Set::Dynamic#update should set a proper action on the item'
		)

		# delete an item
		@sd.update('20091122_1235' => {:delete => true})
		assert_equal(
			{'name' => 'carl','comment' => 'baz'},
			@sd.item('20091122_1235').val,
			'Set::Dynamic#update should not update the values of the item when deleting'
		)
		assert_equal(
			:delete,
			@sd.item('20091122_1235').action,
			'Set::Dynamic#update should set a proper action on the item'
		)

		# before the commit
		assert_equal(
			:update,
			@sd.action,
			'Set::Dynamic#update should set a proper action'
		)
		assert_equal(
			{
				'20091122_1234' => {'name' => 'frank','comment' => 'bar'},
				'20091122_1235' => {'name' => 'carl', 'comment' => 'baz'},
			},
			@sd.val,
			'Set::Dynamic#update should not touch the original values in the storage'
		)

		@sd.commit

		# after the commit
		assert(
			!@sd.pending?,
			'Set::Dynamic#commit should clear the pending status of the items'
		)
		assert_equal(
			{
				'20091122_1234' => {'name' => 'frank','comment' => 'qux'},
				'new!'          => {'name' => 'roy',  'comment' => 'hi.'},
			},
			@sd.val,
			'Set::Dynamic#commit should update the original values in the storage'
		)
		assert_equal(
			:update,
			@sd.result,
			'Set::Dynamic#commit should set own @result'
		)
		assert_equal(
			:update,
			@sd.item('20091122_1234').result,
			'Set::Dynamic#commit should set @result for the items'
		)
		assert_equal(
			:delete,
			@sd.item('20091122_1235').result,
			'Set::Dynamic#commit should set @result for the items'
		)
		assert_equal(
			:create,
			@sd.item('_1236').result,
			'Set::Dynamic#commit should set @result for the items'
		)
	end

	def test_update_with_eclectic_val
		@sd.load(
			'20091122_1234' => {'name' => 'frank','comment' => 'bar'},
			'20091122_1235' => {'name' => 'carl', 'comment' => 'baz'}
		)
		s = @sd.storage

		assert_nothing_raised(
			'Set::Dynamic#update should work with values other than sub-items'
		) {
			@sd.update('20091122_1234' => {'comment' => 'qux'},:conds => {},:action => nil)
		}
		assert_equal(
			{'name' => 'frank','comment' => 'qux'},
			@sd.item('20091122_1234').val,
			'Set::Dynamic#update should update the values of the item instance'
		)
	end

	def test_delete
		@sd.delete
		assert_equal(
			:delete,
			@sd.action,
			'Set::Dynamic#delete should set @action'
		)
	end

	def test_get_by_nobody
		@sd.load(
			'20091122_0001' => {'_owner' => 'frank','comment' => 'bar'},
			'20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
		)
		Sofa.client = nil

		arg = {:action => :update}
		@sd.get arg
		assert_equal(
			:read,
			arg[:action],
			'Set::Dynamic#get should retreat from the forbidden action'
		)
	end

	def test_post_by_nobody
		@sd.load(
			'20091122_0001' => {'_owner' => 'frank','comment' => 'bar'},
			'20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
		)
		Sofa.client = nil

		assert_raise(
			Sofa::Error::Forbidden,
			"'nobody' should not create a new item"
		) {
			@sd.update('_0001' => {'comment' => 'qux'})
		}
		assert_raise(
			Sofa::Error::Forbidden,
			"'nobody' should not update frank's item"
		) {
			@sd.update('20091122_0001' => {'comment' => 'qux'})
		}
		assert_raise(
			Sofa::Error::Forbidden,
			"'nobody' should not delete frank's item"
		) {
			@sd.update('20091122_0001' => {'_action' => 'delete'})
		}
	end

	def test_get_by_carl
		@sd.load(
			'20091122_0001' => {'_owner' => 'frank','comment' => 'bar'},
			'20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
		)
		Sofa.client = 'carl' # carl is not the member of the group

		arg = {:action => :create}
		@sd.get arg
		assert_equal(
			:read,
			arg[:action],
			'Set::Dynamic#get should retreat from the forbidden action'
		)

		arg = {:action => :update}
		@sd.get arg
		assert_equal(
			:update,
			arg[:action],
			'Set::Dynamic#get should keep the partially-permitted action'
		)

		arg = {:action => :update,:conds => {:id => '20091122_0002'}}
		@sd.get arg
		assert_equal(
			:update,
			arg[:action],
			'Set::Dynamic#get should keep the permitted action'
		)
	end

	def test_post_by_carl
		@sd.load(
			'20091122_0001' => {'_owner' => 'frank','comment' => 'bar'},
			'20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
		)
		Sofa.client = 'carl' # carl is not the member of the group

		assert_raise(
			Sofa::Error::Forbidden,
			'carl should not create a new item'
		) {
			@sd.update('_0001' => {'comment' => 'qux'})
		}
		assert_raise(
			Sofa::Error::Forbidden,
			"carl should not update frank's item"
		) {
			@sd.update('20091122_0001' => {'comment' => 'qux'})
		}
		assert_nothing_raised(
			'carl should be able to update his own item'
		) {
			@sd.update('20091122_0002' => {'comment' => 'qux'})
		}
		assert_raise(
			Sofa::Error::Forbidden,
			"carl should not delete frank's item"
		) {
			@sd.update('20091122_0001' => {'_action' => 'delete'})
		}
	end

	def test_get_by_roy
		@sd.load(
			'20091122_0001' => {'_owner' => 'frank','comment' => 'bar'},
			'20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
		)
		Sofa.client = 'roy' # roy belongs to the group

		arg = {:action => :create}
		@sd.get arg
		assert_equal(
			:create,
			arg[:action],
			'Set::Dynamic#get should keep the permitted action'
		)

		arg = {:action => :delete}
		@sd.get arg
		assert_equal(
			:read,
			arg[:action],
			'Set::Dynamic#get should retreat from the forbidden action'
		)
	end

	def test_post_by_roy
		@sd.load(
			'20091122_0001' => {'_owner' => 'frank','comment' => 'bar'},
			'20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
		)
		Sofa.client = 'roy' # roy belongs to the group

		assert_nothing_raised(
			'roy should be able to create a new item'
		) {
			@sd.update('_0001' => {'comment' => 'qux'})
		}
		assert_nothing_raised(
			"roy should be able to update frank's item"
		) {
			@sd.update('20091122_0001' => {'comment' => 'qux'})
		}
		assert_raise(
			Sofa::Error::Forbidden,
			"roy should not delete frank's item"
		) {
			@sd.update('20091122_0001' => {'_action' => 'delete'})
		}
	end

	def test_get_by_root
		@sd.load(
			'20091122_0001' => {'_owner' => 'frank','comment' => 'bar'},
			'20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
		)
		Sofa.client = 'root' # root is the admin

		arg = {:action => :create,:db => 1}
		@sd.get arg
		assert_equal(
			:create,
			arg[:action],
			'Set::Dynamic#get should keep the permitted action'
		)

		arg = {:action => :delete}
		@sd.get arg
		assert_equal(
			:delete,
			arg[:action],
			'Set::Dynamic#get should keep the permitted action'
		)
	end

	def test_post_by_root
		@sd.load(
			'20091122_0001' => {'_owner' => 'frank','comment' => 'bar'},
			'20091122_0002' => {'_owner' => 'carl', 'comment' => 'baz'}
		)
		Sofa.client = 'root' # root is the admin

		assert_nothing_raised(
			'frank should be able to create a new item'
		) {
			@sd.update('_0001' => {'comment' => 'qux'})
		}
		assert_nothing_raised(
			'frank should be able to update his own item'
		) {
			@sd.update('20091122_0001' => {'comment' => 'qux'})
		}
		assert_nothing_raised(
			"frank should be able to update carl's item"
		) {
			@sd.update('20091122_0002' => {'comment' => 'qux'})
		}
		assert_nothing_raised(
			'frank should be able to delete his own item'
		) {
			@sd.update('20091122_0001' => {'_action' => 'delete'})
		}
		assert_nothing_raised(
			"frank should be able to delete carl's item"
		) {
			@sd.update('20091122_0002' => {'_action' => 'delete'})
		}
	end

end
