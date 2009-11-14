# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Set < Test::Unit::TestCase

	def setup
	end

	def teardown
	end

	def test_initialize
		set = Sofa::Set::Static.new(:html => <<'_html')
<html>
	<h1>title:(text 32)</h1>
	<ul id="foo" class="sofa-blog">
		<li>
			subject:(text 64)
			body:(textarea 72*10)
			<ul><li>qux</li></ul>
		</li>
	</ul>
</html>
_html
		assert_equal(
			{
				'title' => {:klass => 'text',:tokens => ['32']},
				'foo'   => {
					:klass    => 'set-dynamic',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl',
<ul id="foo" class="sofa-blog">$()</ul>
_tmpl
					:set_html => <<'_html',
		<li>
			subject:(text 64)
			body:(textarea 72*10)
			<ul><li>qux</li></ul>
		</li>
_html
				},
			},
			set[:item],
			'Set::Static#initialize should load @meta'
		)
	end

	def test_item
		set = Sofa::Set::Static.new(:html => <<'_html')
<html>
	<h1>title:(text 32)</h1>
	<ul id="main" class="sofa-blog">
		<li>hi</li>
	</ul>
</html>
_html
		title = set.item('title')
		assert_instance_of(
			Sofa::Text,
			title,
			'Set::Static#item() should return the child item on the fly'
		)
		assert_equal(
			title.object_id,
			set.item('title').object_id,
			'Set::Static#item() should cache the loaded items'
		)
		assert_equal(
			32,
			title[:size],
			'Set::Static#item() should load the metas of child items'
		)

		main = set.item('main')
		assert_instance_of(
			Sofa::Set::Static::Dynamic,
			main,
			'Set::Static#item() should return the child item on the fly'
		)
		assert_equal(
			main.object_id,
			set.item('main').object_id,
			'Set::Static#item() should cache the loaded items'
		)
		assert_equal(
			"\t\t<li>hi</li>\n",
			main[:set_html],
			'Set::Static#item() should load the metas of child items'
		)
	end

	def test_val
		set = Sofa::Set::Static.new(:html => <<'_html')
<li>
	name:(text): comment:(text)
</li>
_html
		set.item('name').load 'foo'
		assert_equal(
			{'name' => 'foo'},
			set.val,
			'Set::Static#val should not include the value of the empty item'
		)
		set.item('comment').load 'bar'
		assert_equal(
			{'name' => 'foo','comment' => 'bar'},
			set.val,
			'Set::Static#val should not include the value of the empty item'
		)
	end

	def test_get
		set = Sofa::Set::Static.new(:html => <<'_html')
<li>
	name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
		set.load_default
		assert_equal(
			<<'_html',
<li>
	nobody: peek a boo
</li>
_html
			set.get,
			'Set::Static#get should return the html by [:tmpl]'
		)

		comment = set.item('comment')
		def comment._get_foo(arg)
			'foo foo'
		end
		assert_equal('foo foo',set.item('comment').get(:action => 'foo'))
		assert_equal(
			<<'_html',
<li>
	nobody: foo foo
</li>
_html
			set.get(:action => 'foo'),
			'Set::Static#get should pass :action to the child items'
		)
	end

	def test_recursive_tmpl
		set = Sofa::Set::Static.new(:html => <<'_html')
<li>$()</li>
_html
		assert_nothing_raised(
			'Set::Static#get should avoid recursive reference to [:tmpl]'
		) {
			set.get
		}
	end

	def test_load_default
		set = Sofa::Set::Static.new(:html => <<'_html')
<li>
	name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
		set.load_default
		assert_equal(
			'nobody',
			set.item('name').val,
			'Set::Static#load_default should load all the child items with their [:default]'
		)
		assert_equal(
			'peek a boo',
			set.item('comment').val,
			'Set::Static#load_default should load all the child items with their [:default]'
		)
	end

	def test_load
		set = Sofa::Set::Static.new(:html => <<'_html')
<li>
	name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
		set.load('name' => 'carl')
		assert_equal(
			{'name' => 'carl'},
			set.val,
			'Set::Static#load should not touch the item for which value is not given'
		)
		set.load('name' => 'frank','comment' => 'cut the schmuck some slack.')
		assert_equal(
			{'name' => 'frank','comment' => 'cut the schmuck some slack.'},
			set.val,
			'Set::Static#load should load the items at once'
		)
		set.load('name' => 'carl')
		assert_equal(
			{'name' => 'carl','comment' => 'cut the schmuck some slack.'},
			set.val,
			'Set::Static#load should not touch the item for which value is not given'
		)
	end

	def test_create
		set = Sofa::Set::Static.new(:html => <<'_html')
<li>
	name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
		set.create('name' => 'carl')
		assert_equal(
			{'name' => 'carl'},
			set.val,
			'Set::Static#create should not touch the item for which value is not given'
		)
	end

	def test_update
		set = Sofa::Set::Static.new(:html => <<'_html')
<li>
	name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
		set.update('name' => 'carl')
		assert_equal(
			{'name' => 'carl'},
			set.val,
			'Set::Static#update should not touch the item for which value is not given'
		)
		set.update('name' => 'frank','comment' => 'cut the schmuck some slack.')
		assert_equal(
			{'name' => 'frank','comment' => 'cut the schmuck some slack.'},
			set.val,
			'Set::Static#udpate should load the items at once'
		)
		set.update('name' => 'carl')
		assert_equal(
			{'name' => 'carl','comment' => 'cut the schmuck some slack.'},
			set.val,
			'Set::Static#update should not touch the item for which value is not given'
		)
	end

	def test_delete
		set = Sofa::Set::Static.new(:html => <<'_html')
<li>
	name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
		set.item('name').load 'foo'

		set.delete
		assert_equal(
			:delete,
			set.action,
			'Set::Static#delete should set @action'
		)
		assert_equal(
			{'name' => 'foo'},
			set.val,
			'Set::Static#delete should not touch any item'
		)
	end

end
