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
			folder.send(:merge_meta,index,summary),
			'Folder#merge_meta should merge parsed metas'
		)
	end

	def test_tmpl_summary
		folder = Sofa::Set::Static::Folder.root.item('t_summary')
		assert_equal(
			<<'_html',
<h1>index</h1>
$(main)
_html
			folder[:tmpl],
			'Folder#initialize should load [:tmpl] from [:dir]/index.html'
		)
		assert_equal(
			<<'_html',
<h1>summary</h1>
$(main)
_html
			folder[:tmpl_summary],
			'Folder#initialize should load [:tmpl_summary] from [:dir]/summary.html'
		)

		assert_equal(
			<<'_html'.chomp,
$(.message)<ul id="@(name)" class="sofa-blog">
$()</ul>
$(.navi)$(.submit)$(.action_create)
_html
			folder[:item]['main'][:tmpl],
			'Folder#initialize should load [:tmpl] of the child items'
		)
		assert_equal(
			<<'_html'.chomp,
$(.message)<table id="@(name)" class="sofa-blog">
$()</table>
$(.navi)$(.submit)$(.action_create)
_html
			folder[:item]['main'][:tmpl_summary],
			'Folder#initialize should load [:tmpl_summary] of the child items'
		)

		assert_equal(
			<<'_html',
	<li>$(name)$(.action_update): $(comment)</li>
_html
			folder[:item]['main'][:item]['default'][:tmpl],
			'Folder#initialize should load [:tmpl] of all the decendant items'
		)
		assert_equal(
			<<'_html',
	<tr><td>$(name)$(.action_update)</td><td>$(comment)</td></tr>
_html
			folder[:item]['main'][:item]['default'][:tmpl_summary],
			'Folder#initialize should load [:tmpl_summary] of all the decendant items'
		)
	end

end
