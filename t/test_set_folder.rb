# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Set_Folder < Test::Unit::TestCase

	def setup
	end

	def teardown
	end

	def test_root
		root = Sofa::Set::Static::Folder.root
		assert_instance_of(
			Sofa::Set::Static::Folder,
			root,
			'Folder.root should return the root folder instance'
		)
	end

	def test_initialize
		folder = Sofa::Set::Static::Folder.new(:id => 'foo',:parent => nil)
		assert_match(
			/^<html>/,
			folder[:html],
			'Folder#initialize should load [:html] from [:dir]/index.html'
		)
		assert_instance_of(
			Sofa::Set::Dynamic,
			folder.item('main'),
			'Folder#initialize should load the items according to [:html]'
		)
	end

	def test_meta_html_dir
		folder = Sofa::Set::Static::Folder.root.item('foo')
		assert_equal(
			'/foo',
			folder[:html_dir],
			"Folder#meta_html_dir should return meta_dir if there is 'index.html'"
		)

		folder = Sofa::Set::Static::Folder.root.item('foo','bar')
		assert_equal(
			'/foo',
			folder[:html_dir],
			"Folder#meta_html_dir should return parent[:html_dir] if there is no 'index.html' in [:dir]"
		)
	end

	def test_default_items
		folder = Sofa::Set::Static::Folder.new(:id => 'foo',:parent => nil)
		assert_instance_of(
			Sofa::Text,
			folder.item('_label'),
			'Folder#initialize should always load the default items'
		)
		assert_equal(
			'Foo Folder',
			folder.val('_label'),
			'Folder#initialize should load the val from [:dir].yaml'
		)
		assert_equal(
			'frank',
			folder.val('_owner'),
			'Folder#initialize should load the val from [:dir].yaml'
		)
	end

	def test_child_folder
		folder = Sofa::Set::Static::Folder.new(:id => 'foo',:parent => nil)
		child  = folder.item('bar')
		assert_instance_of(
			Sofa::Set::Static::Folder,
			child,
			'Folder#item should look the real directory for the child item'
		)
		assert_equal(
			'Bar Folder',
			child.val('_label'),
			'Folder#initialize should load the val from [:dir].yaml'
		)
		assert_equal(
			'frank',
			child.val('_owner'),
			'Folder#initialize should inherit the val of default items from [:parent]'
		)
	end

	def test_item
		folder = Sofa::Set::Static::Folder.root.item('foo')
		assert_instance_of(
			Sofa::Set::Static,
			folder.item('main','20091120_0001'),
			'Folder#item should work just like any other sets'
		)
		assert_instance_of(
			Sofa::Set::Static,
			folder.item('20091120_0001'),
			"Folder#item should delegate to item('main') if full-formatted :id is given"
		)
	end

	def test_merge_meta
		folder = Sofa::Set::Static::Folder.root

		index = {
			:item => {
				'main' => {
					:item => {
						'default' => {
							:tmpl => '<li><ul>$(files)</ul></li>',
							:item => {
								'files' => {
									:tmpl => '<ol>$()</ol>',
									:item => {
										'default' => {
											:tmpl => '<li>$(file)</li>',
											:item => {'file' => {:klass => 'text'}},
										},
									},
								},
							},
						},
					},
					:tmpl => '<ul>$()</ul>',
				},
			},
			:tmpl => '<html>$(main)</html>',
		}
		summary = {
			:item => {
				'main' => {
					:foo  => 'this should not be merged.',
					:item => {
						'default' => {
							:bar  => 'this should not be merged.',
							:tmpl => '<li class ="s"><ul>$(files)</ul></li>',
							:item => {
								'files' => {
									:baz  => 'this should not be merged.',
									:tmpl => '<ol class ="s">$()</ol>',
									:item => {
										'default' => {
											:qux  => 'this should not be merged.',
											:tmpl => '<li class ="s">$(file)</li>',
										},
									},
								},
							},
						},
					},
					:tmpl => '<ul class ="s">$()</ul>',
				},
			},
			:tmpl => '<html class ="s">$(main)</html>',
		}

		assert_equal(
			{
				:item => {
					'main' => {
						:item => {
							'default' => {
								:tmpl => '<li><ul>$(files)</ul></li>',
								:tmpl_summary => '<li class ="s"><ul>$(files)</ul></li>',
								:item => {
									'files' => {
										:tmpl => '<ol>$()</ol>',
										:tmpl_summary => '<ol class ="s">$()</ol>',
										:item => {
											'default' => {
												:tmpl => '<li>$(file)</li>',
												:tmpl_summary => '<li class ="s">$(file)</li>',
												:item => {'file' => {:klass => 'text'}},
											},
										},
									},
								},
							},
						},
						:tmpl => '<ul>$()</ul>',
						:tmpl_summary => '<ul class ="s">$()</ul>',
					},
				},
				:tmpl => '<html>$(main)</html>',
				:tmpl_summary => '<html class ="s">$(main)</html>',
			},
			folder.send(:merge_meta,index,summary,:summary),
			'Folder#merge_meta should merge parsed metas'
		)
	end

	def test_tmpl_summary
		folder = Sofa::Set::Static::Folder.root.item('t_summary')
		assert_equal(
			<<'_html'.chomp,
<h1>index</h1>
$(main.message)$(main)
_html
			folder[:tmpl],
			'Folder#initialize should load [:tmpl] from [:dir]/index.html'
		)
		assert_equal(
			<<'_html'.chomp,
<h1>summary</h1>
$(main.message)$(main)
_html
			folder[:tmpl_summary],
			'Folder#initialize should load [:tmpl_summary] from [:dir]/summary.html'
		)

		assert_equal(
			<<'_html'.chomp,
<ul id="@(name)" class="sofa-blog">
$()</ul>
$(.navi)$(.submit)$(.action_create)
_html
			folder[:item]['main'][:tmpl],
			'Folder#initialize should load [:tmpl] of the child items'
		)
		assert_equal(
			<<'_html'.chomp,
<table id="@(name)" class="sofa-blog">
$()</table>
$(.navi)$(.submit)$(.action_create)
_html
			folder[:item]['main'][:tmpl_summary],
			'Folder#initialize should load [:tmpl_summary] of the child items'
		)

		assert_equal(
			<<'_html',
	<li>$(.a_update)$(name)</a>: $(comment)$(.hidden)</li>
_html
			folder[:item]['main'][:item]['default'][:tmpl],
			'Folder#initialize should load [:tmpl] of all the decendant items'
		)
		assert_equal(
			<<'_html',
	<tr><td><a href="$(.uri_detail)">$(name)</a></td><td>$(comment)</td></tr>
_html
			folder[:item]['main'][:item]['default'][:tmpl_summary],
			'Folder#initialize should load [:tmpl_summary] of all the decendant items'
		)
	end

	def test_get_summary
		folder = Sofa::Set::Static::Folder.root.item('t_summary')

		assert_equal(
			<<'_html',
<h1>summary</h1>
<table id="main" class="sofa-blog">
	<tr><td><a href="/t_summary/20100326/1/read_detail.html">frank</a></td><td>hi.</td></tr>
</table>
_html
			folder.get(
				'main' => {:conds => {:p => 1}}
			),
			'Set#get should use [:tmpl_summary] when available and appropriate'
		)
		assert_equal(
			<<'_html',
<h1>index</h1>
<ul id="main" class="sofa-blog">
	<li><a>frank</a>: hi.</li>
</ul>
_html
			folder.get(
				:action => :read,
				:sub_action => :detail,
				'main' => {:action => :read,:sub_action => :detail,:conds => {:p => 1}}
			),
			'Set#get should not use [:tmpl_summary] for :read -> :detail'
		)

		Sofa.client = 'root'
		Sofa.current[:base] = folder.item('main')
		folder.item('main')[:tid] = '12345.012'
		assert_equal(
			<<'_html',
<h1>index</h1>
<form id="main" method="post" enctype="multipart/form-data" action="/t_summary/12345.012/update.html">
<ul id="main" class="sofa-blog">
	<li><a><input type="text" name="20100326_0001-name" value="frank" class="" /></a>: <input type="text" name="20100326_0001-comment" value="hi." class="" /></li>
</ul>
<input name=".status-public" type="submit" value="update" />
<input name=".action-confirm_delete" type="submit" value="delete..." />
</form>
_html
			folder.get(
				:action => :read,
				:sub_action => :detail,
				'main' => {:action => :update,:sub_action => nil,:conds => {:p => 1}}
			),
			'Set#get should not use [:tmpl_summary] for :update'
		)
	end

end
