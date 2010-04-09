# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_File < Test::Unit::TestCase

	def setup
		@file = Class.new
		@file.stubs(:rewind).returns(nil)
		@file.stubs(:read).returns('this is file body')

		meta = nil
		Sofa::Parser.gsub_scalar('$(foo file 1..50)') {|id,m|
			meta = m
			''
		}
		@f = Sofa::Field.instance meta.merge(:id => 'foo')
	end

	def test_meta
		assert_equal(
			1,
			@f[:min],
			'File#initialize should set :min from the range token'
		)
		assert_equal(
			50,
			@f[:max],
			'File#initialize should set :max from the range token'
		)
	end

	def test_meta_path
		@f[:parent] = Sofa::Set::Static::Folder.root.item('t_file','main')
		assert_equal(
			'/t_file/main/foo',
			@f[:path],
			'File#meta_path should return the full path to the field'
		)
	end

	def test_meta_persistent_sd
		root = Sofa::Set::Static::Folder.root.item('t_file','main')
		parent = Sofa::Set::Dynamic.new(:id => 'boo',:parent => root)
		@f[:parent] = parent
		assert_equal(
			root,
			@f[:persistent_sd],
			'File#persistent_sd should return the nearest persient sd'
		)
	end

	def test_meta_persistent_name
		root = Sofa::Set::Static::Folder.root.item('t_file','main')
		parent = Sofa::Set::Dynamic.new(:id => 'boo',:parent => root)
		@f[:parent] = parent
		assert_equal(
			'boo-foo',
			@f[:persistent_name],
			'File#persistent_name should return the path to [:persistent_sd]'
		)
	end

	def test_val_cast_from_rack
		@f.create(
			:type     => 'image/jpeg',
			:tempfile => @file,
			:head     => <<'_eos',
Content-Disposition: form-data; name="t_file"; filename="baz.jpg"
Content-Type: image/jpeg
_eos
			:filename => 'baz.jpg',
			:name     => 't_file'
		)

		assert_equal(
			{
				'basename' => 'baz.jpg',
				'type'     => 'image/jpeg',
				'size'     => @file.read.size,
			},
			@f.val,
			'File#val_cast should re-map a hash from Rack'
		)
		assert_equal(
			@file.read,
			@f.body,
			'File#val_cast should store the file body in @body'
		)
	end

	def test_val_cast_load
		@f.load(
			'basename' => 'baz.jpg',
			'type'     => 'image/jpeg',
			'size'     => 123
		)
		assert_equal(
			{
				'basename' => 'baz.jpg',
				'type'     => 'image/jpeg',
				'size'     => 123,
			},
			@f.val,
			'File#val_cast should load() a hash without :tempfile like Set#load'
		)

		@f.load(
			{}
		)
		assert_equal(
			{},
			@f.val,
			'File#val_cast should load() a hash without :tempfile like Set#load'
		)
	end

	def test_save_file
		Sofa.client = 'root'
		sd = Sofa::Set::Static::Folder.root.item('t_file','main')
		sd.storage.clear

		# create a new set with file items
		sd.update(
			'_1' => {
				'foo' => {
					:type     => 'image/jpeg',
					:tempfile => @file,
					:head     => <<'_eos',
Content-Disposition: form-data; name="t_file"; filename="foo.jpg"
Content-Type: image/jpeg
_eos
					:filename => 'foo.jpg',
					:name     => 't_file'
				},
			}
		)
		assert_nothing_raised(
			'File#commit should commit files nicely'
		) {
			sd.commit :persistent
		}
		id = sd.result.values.first[:id]

		item = Sofa::Set::Static::Folder.root.item('t_file','main',id,'foo')
		assert_instance_of(
			Sofa::File,
			item,
			'File#commit should commit the file item'
		)
		assert_equal(
			@file.read,
			item.body,
			'File#commit should store the body of the file item'
		)

		# update the sibling file item
		sd.update(
			id => {
				'bar' => {
					:type     => 'image/png',
					:tempfile => @file,
					:head     => <<'_eos',
Content-Disposition: form-data; name="t_file"; filename="bar.png"
Content-Type: image/png
_eos
					:filename => 'bar.png',
					:name     => 't_file'
				},
			}
		)
		sd.commit :persistent

		assert_equal(
			@file.read,
			Sofa::Set::Static::Folder.root.item('t_file','main',id,'bar').body,
			'File#commit should store the body of the file item'
		)
		assert_equal(
			@file.read,
			Sofa::Set::Static::Folder.root.item('t_file','main',id,'foo').body,
			'File#commit should keep the body of the untouched file item'
		)
	end

	def test_delete_file
		Sofa.client = 'root'
		sd = Sofa::Set::Static::Folder.root.item('t_file','main')
		sd.storage.clear

		sd.update(
			'_1' => {
				'foo' => {
					:type     => 'image/jpeg',
					:tempfile => @file,
					:head     => <<'_eos',
Content-Disposition: form-data; name="t_file"; filename="foo.jpg"
Content-Type: image/jpeg
_eos
					:filename => 'baz.jpg',
					:name     => 't_file'
				},
				'bar' => {
					:type     => 'image/jpeg',
					:tempfile => @file,
					:head     => <<'_eos',
Content-Disposition: form-data; name="t_file"; filename="bar.jpg"
Content-Type: image/jpeg
_eos
					:filename => 'bar.jpg',
					:name     => 't_file'
				},
			}
		)
		sd.commit :persistent

		id = sd.result.values.first[:id]

		sd = Sofa::Set::Static::Folder.root.item('t_file','main')
		sd.update(
			id => {:action => :delete}
		)
		sd.commit :persistent

		assert_equal(
			{},
			sd.val,
			''
		)
	end

end
