# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_List < Test::Unit::TestCase

	def setup
		@list = Sofa::Set::Dynamic.new(
			:id       => 'main',
			:klass    => 'set-dynamic',
			:parent   => Sofa::Field.instance(:id => 'foo',:klass => 'set-static-folder'),
			:workflow => 'blog',
			:tmpl     => <<'_tmpl',
<ul id="foo" class="sofa-blog">
$()</ul>
_tmpl
			:set_html => <<'_html'
	<li>
		name:(text 32)
		comment:(text 64)
	</li>
_html
		)
	end

	def teardown
	end

def ptest_storage
	assert_instance_of(
		Sofa::Storage,
		@list.instance_variable_get(:@storage),
		'List#instance should load an apropriate storage for the list'
	)
end

def test_item
	assert_instance_of(
		Sofa::Set,
		@list.item('091107_0001'),
		'list#item() should return the child set in the storage'
	) if nil
end

def ptest_val
	list.item('name').load 'foo'
	assert_equal(
		{'name' => 'foo'},
		list.val,
		'list#val should not include the value of the empty item'
	)
	list.item('comment').load 'bar'
	assert_equal(
		{'name' => 'foo','comment' => 'bar'},
		list.val,
		'list#val should not include the value of the empty item'
	)
end

def ptest_get
	assert_equal(
		<<'_html',
<li>
nobody: peek a boo
</li>
_html
		list.get,
		'list#get should return the html by [:tmpl]'
	)
end

def ptest_recursive_tmpl
	list = Sofa::Set::Dynamic.new(:html => <<'_html')
<li>$()</li>
_html
	assert_nothing_raised(
		'list#get should avoid recursive reference to [:tmpl]'
	) {
		list.get
	}
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
