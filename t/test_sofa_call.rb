# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'rubygems'
require 'rack'

class TC_Sofa_Call < Test::Unit::TestCase

	def setup
		@sofa = Sofa.new
	end

	def teardown
	end

	def test_get
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/foo/'
		)
		assert_match(
			/<html/,
			res.body,
			'Sofa#call() should return the folder.get if the base field is a SD'
		)
	end

	def test_get_non_exist
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/foo/non/exist/'
		)
		assert_equal(
			404,
			res.status,
			'Sofa#call() should return 404 if the given path is non-existent'
		)
	end

	def test_get_partial
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/foo/20091120_0001/name/'
		)
		assert_equal(
			'FZ',
			res.body,
			'Sofa#call() should return the base.get unless the base field is a SD'
		)
	end

	def test_post_simple_create
		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_store/main/update.html',
			{
				:input => "_1-name=fz&_1-comment=hi.&.status-public=create"
			}
		)
		assert_equal(
			303,
			res.status,
			'Sofa#call with post method should return status 303'
		)
		assert_match(
			/id=\d+_\d+/,
			res.headers['Location'],
			'Sofa#call with post method should return a proper location'
		)

		new_id = res.headers['Location'][/id=(\d+_\d+)/,1]
		assert_equal(
			{'name' => 'fz','comment' => 'hi.'},
			Sofa::Set::Static::Folder.root.item('t_store','main',new_id).val,
			'Sofa#call with post method should store the item in the storage'
		)
	end

	def test_post_with_attachment
		Sofa::Set::Static::Folder.root.item('t_attachment','main').storage.clear

		# post an attachment
		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_attachment/main/update.html',
			{
				:input => "_012-files-_1-file=wow.jpg&_012-files.status-public=create"
			}
		)
		assert_match(
			'update.html',
			res.headers['Location'],
			'Sofa#call without the root status should always return :update'
		)
		assert_equal(
			{},
			Sofa::Set::Static::Folder.root.item('t_attachment','main').val,
			'Sofa#call without the root status should not update the persistent storage'
		)

		tid = res.headers['Location'][Sofa::REX::TID]
		assert_instance_of(
			Sofa::Set::Dynamic,
			Sofa.transaction[tid],
			'the suspended SD should be kept in Sofa.transaction'
		)
		assert_equal(
			{},
			Sofa.transaction[tid].send(:pending_items),
			'the suspended SD should be committed :temp'
		)

		# post the item
		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/#{tid}/update.html",
			{
				:input => "_012-comment=hello.&.status-public=create"
			}
		)
		assert_no_match(
			/update\.html/,
			res.headers['Location'],
			'Sofa#call with the root status should commit the transaction'
		)
		assert_not_equal(
			{},
			Sofa::Set::Static::Folder.root.item('t_attachment','main').val,
			'Sofa#call with the root status should update the persistent storage'
		)

		new_id   = res.headers['Location'][/id=(\d+_\d+)/,1]
		new_item = Sofa::Set::Static::Folder.root.item('t_attachment','main',new_id)
		assert_not_equal(
			{},
			new_item.val,
			'Sofa#call with the root status should commit all the pending items'
		)
		assert_equal(
			'hello.',
			new_item.val['comment'],
			'Sofa#call with the root status should commit the root items'
		)
		assert_equal(
			{'file' => 'wow.jpg'},
			new_item.val['files'].values.first,
			'Sofa#call with the root status should commit the descendant items'
		)

		# post a reply
		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/1234567890.123456/t_attachment/main/#{new_id}/replies/update.html",
			{
				:input => "_001-reply=wow.&.status-public=create"
			}
		)
		assert_equal(303,res.status)
		assert_match(
			%r{/#{new_id}/replies/index.html},
			res.headers['Location'],
			'Sofa#call with a sub-app status should commit the root item'
		)
		assert_not_equal(
			{},
			Sofa::Set::Static::Folder.root.item('t_attachment','main',new_id,'replies').val,
			'Sofa#call with a sub-app status should update the persistent storage'
		)
	end

end
