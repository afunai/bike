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
	<li>name:(text 32): comment:(text 64)</li>
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

def ptest_load_default
	list = Sofa::Set::Dynamic.new(:html => <<'_html')
<li>
name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
	list.load_default
	assert_equal(
		'nobody',
		list.item('name').val,
		'list#load_default should load all the child items with their [:default]'
	)
end

def ptest_load
	list = Sofa::Set::Dynamic.new(:html => <<'_html')
<li>
name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
	list.load('name' => 'carl')
	assert_equal(
		{'name' => 'carl'},
		list.val,
		'list#load should not touch the item for which value is not given'
	)
end

def ptest_create
	list = Sofa::Set::Dynamic.new(:html => <<'_html')
<li>
name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
	list.create('name' => 'carl')
	assert_equal(
		{'name' => 'carl'},
		list.val,
		'list#create should not touch the item for which value is not given'
	)
end

def ptest_update
	list = Sofa::Set::Dynamic.new(:html => <<'_html')
<li>
name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
	list.update('name' => 'carl')
	assert_equal(
		{'name' => 'carl'},
		list.val,
		'list#update should not touch the item for which value is not given'
	)
end

def ptest_delete
	list = Sofa::Set::Dynamic.new(:html => <<'_html')
<li>
name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
	list.item('name').load 'foo'

	list.delete
	assert(
		list.deleted?,
		'list#delete should list deleted?() to true'
	)
end

end
