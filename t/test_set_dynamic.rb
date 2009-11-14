# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Set_Dynamic < Test::Unit::TestCase

	class Sofa::Text
		def _get_test_sd(arg)
			'moo!'
		end
	end

	def setup
		@sd = Sofa::Set::Dynamic.new(
			:id       => 'main',
			:klass    => 'set-dynamic',
			:workflow => 'blog',
			:tmpl     => <<'_tmpl',
<ul id="foo" class="sofa-blog">
$()</ul>
_tmpl
			:set_html => <<'_html'
	<li>name:(text 32 :'nobody'): comment:(text 64 :'hi.')</li>
_html
		)
	end

	def teardown
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
		assert_equal(
			<<'_html',
<ul id="foo" class="sofa-blog">
	<li>moo!: moo!</li>
</ul>
_html
			@sd.get(:conds => {:id => '1235'},:action => 'test_sd'),
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
			'1234' => {'name' => 'frank','comment' => 'bar'},
			'1235' => {'name' => 'carl', 'comment' => 'baz'}
		)
		s = @sd.storage
		def s.new_id
			'new!'
		end

		# update an item
		@sd.update('1234' => {'comment' => 'qux'})
		assert_equal(
			{'name' => 'frank','comment' => 'qux'},
			@sd.item('1234').val,
			'Set::Dynamic#update should update the values of the item instance'
		)
		assert_equal(
			:update,
			@sd.item('1234').action,
			'Set::Dynamic#update should set a proper action on the item'
		)
		assert_equal(
			nil,
			@sd.item('1234','name').action,
			'Set::Dynamic#update should set a proper action on the item'
		)
		assert_equal(
			:update,
			@sd.item('1234','comment').action,
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
		@sd.update('1235' => {:delete => true})
		assert_equal(
			{'name' => 'carl','comment' => 'baz'},
			@sd.item('1235').val,
			'Set::Dynamic#update should not update the values of the item when deleting'
		)
		assert_equal(
			:delete,
			@sd.item('1235').action,
			'Set::Dynamic#update should set a proper action on the item'
		)

		# before commit
		assert_equal(
			:update,
			@sd.action,
			'Set::Dynamic#update should set a proper action'
		)
		assert_equal(
			{
				'1234' => {'name' => 'frank','comment' => 'bar'},
				'1235' => {'name' => 'carl', 'comment' => 'baz'},
			},
			@sd.val,
			'Set::Dynamic#update should not touch the original values in the storage'
		)

		@sd.commit

		assert(
			!@sd.pending?,
			'Set::Dynamic#commit should clear the pending status of the items'
		)
		assert_equal(
			{
				'1234' => {'name' => 'frank','comment' => 'qux'},
				'new!' => {'name' => 'roy',  'comment' => 'hi.'},
			},
			@sd.val,
			'Set::Dynamic#commit should update the original values in the storage'
		)
	end

	def test_delete
		@sd.delete
		assert(
			@sd.deleted?,
			'Set::Dynamic#delete should set deleted?() to true'
		)
	end

end
