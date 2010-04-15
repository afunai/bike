# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_File < Test::Unit::TestCase

	def setup
		@file = Class.new
		@file.stubs(:rewind).returns(nil)
		@file.stubs(:read).returns('this is file body')
		@file.stubs(:length).returns(@file.read.length)

		meta = nil
		Sofa::Parser.gsub_scalar('$(foo file 1..50 jpg,gif,png)') {|id,m|
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
		assert_equal(
			['jpg','gif','png'],
			@f[:options],
			'File#initialize should set :options from the csv token'
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

	def test_meta_tmp_path
		@f[:parent] = Sofa::Set::Static::Folder.root.item('t_file','main')
		Sofa.current[:base] = @f[:parent]
		tid = @f[:parent][:tid]

		assert_equal(
			"/#{tid}/foo",
			@f[:tmp_path],
			'File#meta_tmp_path should return the short path from the tid'
		)

		Sofa.current[:base] = nil
		assert_nil(
			@f[:tmp_path],
			'File#meta_tmp_path should return nil unless Sofa.base is set'
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
				'size'     => @file.length,
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

	def test_get
		@f[:parent] = Sofa::Set::Static::Folder.root.item('t_file','main')
		Sofa.current[:base] = @f[:parent]
		tid = @f[:parent][:tid]

		@f.load({})
		assert_nil(
			@f.get,
			'File#get should return nil when the val is empty'
		)

		@f.load(
			'basename' => 'baz.jpg',
			'type'     => 'image/jpeg',
			'size'     => 123
		)
		assert_equal(
			'<span class="file"><a href="/t_file/main/foo/baz.jpg">baz.jpg (123 bytes)</a></span>',
			@f.get,
			'File#get should return proper string'
		)
		assert_equal(
			<<"_html".chomp,
<span class="file"><a href="/#{tid}/foo/baz.jpg">baz.jpg (123 bytes)</a></span>
<span class="file">
	<input type="file" name="foo" class="" />
</span>
_html
			@f.get(:action => :create),
			'File#get should return proper string'
		)

		@f.load(
			'basename' => '<baz>.jpg',
			'type'     => 'image/<jpeg>',
			'size'     => 123
		)
		assert_equal(
			'<span class="file"><a href="/t_file/main/foo/&lt;baz&gt;.jpg">&lt;baz&gt;.jpg (123 bytes)</a></span>',
			@f.get,
			'File#get should escape the special characters in file information'
		)
	end

	def test_get_hidden
		Sofa.client = 'root'
		sd = Sofa::Set::Static::Folder.root.item('t_file','main')
		sd.update(
			'_1' => {
				'baz' => {
					'_1' => {},
				},
			}
		)
		Sofa.current[:base] = sd
		sd[:tid] = '1234.567'

		assert_equal(
			<<'_html'.chomp,

<span class="file">
	<input type="file" name="_1-foo" class="" />
</span>
_html
			sd.item('_1','foo').get(:action => :create),
			'File#get should not include a hidden input if the field is not required'
		)
		assert_equal(
			<<'_html'.chomp,

<span class="file">
	<input type="hidden" name="_1-baz-_1-qux" value="" />
	<input type="file" name="_1-baz-_1-qux" class="" />
</span>
_html
			sd.item('_1','baz','_1','qux').get(:action => :create),
			'File#get should include a hidden input to supplement an empty field'
		)

		sd.update(
			'_1' => {
				'baz' => {
					'_1' => {
						'qux' => {
							:type     => 'image/jpeg',
							:tempfile => @file,
							:head     => <<'_eos',
Content-Disposition: form-data; name="t_file"; filename="qux.jpg"
Content-Type: image/jpeg
_eos
							:filename => 'qux.jpg',
							:name     => 't_file'
						},
					},
				},
			}
		)
		assert_equal(
			<<"_html".chomp,
<span class="file"><a href="/1234.567/_1/baz/_1/qux/qux.jpg">qux.jpg (#{@file.length} bytes)</a></span>
<span class="file">
	<input type="file" name="_1-baz-_1-qux" class="" />
</span>
_html
			sd.item('_1','baz','_1','qux').get(:action => :update),
			'File#get should not include a hidden if the field is not empty'
		)
	end

	def test_get_delete
		Sofa.client = 'root'
		sd = Sofa::Set::Static::Folder.root.item('t_file','main')
		sd.update(
			'_1' => {
				'baz' => {
					'_1' => {},
				},
			}
		)
		Sofa.current[:base] = sd
		sd[:tid] = '1234.567'

		assert_equal(
			<<'_html'.chomp,

<span class="file">
	<input type="file" name="_1-foo" class="" />
</span>
_html
			sd.item('_1','foo').get(:action => :create),
			'File#get should not include a delete submit if the field is empty'
		)

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
		assert_equal(
			<<"_html".chomp,
<span class="file"><a href="/1234.567/_1/foo/foo.jpg">foo.jpg (#{@file.length} bytes)</a></span>
<span class="file">
	<input type="submit" name="_1-foo.action-delete" value="x">
	<input type="file" name="_1-foo" class="" />
</span>
_html
			sd.item('_1','foo').get(:action => :update),
			'File#get should include a delete submit if the field is not empty'
		)

		sd.item('_1','foo')[:min] = 1
		assert_equal(
			<<"_html".chomp,
<span class="file"><a href="/1234.567/_1/foo/foo.jpg">foo.jpg (#{@file.length} bytes)</a></span>
<span class="file">
	<input type="file" name="_1-foo" class="" />
</span>
_html
			sd.item('_1','foo').get(:action => :update),
			'File#get should not include a delete submit if the field is mandatory'
		)
	end

	def test_call_body
		Sofa.client = 'root'
		sd = Sofa::Set::Static::Folder.root.item('t_file','main')
		sd.storage.clear

		# post a multipart request
		input = <<"_eos".gsub(/\r?\n/,"\r\n")
---foobarbaz
Content-Disposition: form-data; name="_1-foo"; filename="foo.jpg"
Content-Type: image/jpeg

#{@file.read}
---foobarbaz--
_eos
		res = Rack::MockRequest.new(Sofa.new).post(
			'http://example.com/t_file/main/update.html',
			{
				:input           => input,
				'CONTENT_TYPE'   => 'multipart/form-data; boundary=-foobarbaz',
				'CONTENT_LENGTH' => input.length,
			}
		)
		tid = res.headers['Location'][Sofa::REX::TID]

		assert_equal(
			@file.read,
			Sofa.transaction[tid].item('_1','foo').body,
			'Sofa#call should keep suspended field in Sofa.transaction'
		)

		res = Rack::MockRequest.new(Sofa.new).get(
			"http://example.com/#{tid}/_1/foo/foo.jpg"
		)
		assert_equal(
			@file.read,
			res.body,
			'Sofa#call should be able to access suspended file bodies'
		)

		# commit the base
		res = Rack::MockRequest.new(Sofa.new).post(
			"http://example.com/#{tid}/update.html",
			{
				:input => '.status-public=create',
			}
		)

		res.headers['Location'] =~ Sofa::REX::PATH_ID
		new_id = sprintf('%.8d_%.4d',$1,$2)

		res = Rack::MockRequest.new(Sofa.new).get(
			"http://example.com/t_file/#{new_id}/foo/foo.jpg"
		)
		assert_equal(
			'image/jpeg',
			res.headers['Content-Type'],
			'Sofa#call to a file item should return the mime type of the file'
		)
		assert_equal(
			@file.length.to_s,
			res.headers['Content-Length'],
			'Sofa#call to a file item should return the content length of the file'
		)
		assert_equal(
			@file.read,
			res.body,
			'Sofa#call to a file item should return the binary body of the file'
		)
	end

	def test_errors
		@f.create({})
		@f[:min] = 0
		assert_equal(
			[],
			@f.errors,
			'File#errors should return the errors of the current body'
		)

		@f[:min] = 1
		@f.create({})
		assert_equal(
			['mandatory'],
			@f.errors,
			'File#errors should return the errors of the current body'
		)

		@f[:min] = 1
		@f.delete
		@f.commit :temp
		@f.commit :persistent
		assert_equal(
			['mandatory'],
			@f.errors,
			'File#errors should return the errors of the current body'
		)

		@f.update(
			:type     => 'image/jpeg',
			:tempfile => @file,
			:head     => <<'_eos',
Content-Disposition: form-data; name="t_file"; filename="baz.jpg"
Content-Type: image/jpeg
_eos
			:filename => 'baz.jpg',
			:name     => 't_file'
		)

		@f[:min] = 0
		assert_equal(
			[],
			@f.errors,
			'File#errors should return the errors of the current body'
		)

		@f[:min] = @file.length + 1
		@f[:max] = nil
		assert_equal(
			['too small'],
			@f.errors,
			'File#errors should return the errors of the current body'
		)

		@f[:min] = nil
		@f[:max] = @file.length - 1
		assert_equal(
			['too large'],
			@f.errors,
			'File#errors should return the errors of the current body'
		)

		@f[:min] = nil
		@f[:max] = nil
		@f[:options] = ['txt']
		assert_equal(
			['wrong file type'],
			@f.errors,
			'File#errors should return the errors of the current body'
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
					:filename => 'foo.jpg',
					:name     => 't_file'
				},
			}
		)
		sd.commit :persistent

		id = sd.result.values.first[:id]

		sd = Sofa::Set::Static::Folder.root.item('t_file','main')
		sd.update(
			id => {'foo' => {:action => :delete}}
		)
		assert_equal(:delete,sd.item(id,'foo').action)
		sd.commit :temp

		assert_equal(
			{},
			sd.item(id,'foo').val,
			'File#delete should clear the val of the field'
		)
		assert_equal(
			:delete,
			sd.item(id,'foo').action,
			'File#delete should set @action'
		)

		another_sd = Sofa::Set::Static::Folder.root.item('t_file','main')
		assert_not_equal(
			{},
			another_sd.item(id,'foo').val,
			'File#delete should not clear the persistent val before commit(:persistent)'
		)
		assert_equal(
			@file.read,
			another_sd.item(id,'foo').body,
			'File#delete should not delete the persistent body before commit(:persistent)'
		)

		sd.commit :persistent

		another_sd = Sofa::Set::Static::Folder.root.item('t_file','main')
		assert_equal(
			{},
			another_sd.item(id,'foo').val,
			'File#delete should clear the persistent val after commit(:persistent)'
		)
		assert_nil(
			another_sd.item(id,'foo').body,
			'File#delete should clear the persistent body after commit(:persistent)'
		)
	end

	def test_delete_parent_set
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
			'Set#delete should delete body of the file items'
		)
	end

	def test_save_file_attachment
		Sofa.client = 'root'
		sd = Sofa::Set::Static::Folder.root.item('t_file','main')
		sd.storage.clear

		# create an attachment file item
		sd.update(
			'_1' => {
				'baz' => {
					'_1' => {
						'qux' => {
							:type     => 'image/gif',
							:tempfile => @file,
							:head     => <<'_eos',
Content-Disposition: form-data; name="t_file"; filename="qux.gif"
Content-Type: image/gif
_eos
							:filename => 'qux.gif',
							:name     => 't_file'
						},
					},
				}
			}
		)

		sd.commit :persistent
		baz_id = sd.result.values.first[:id]
		qux_id = sd.result.values.first.item('baz').val.keys.first

		item = Sofa::Set::Static::Folder.root.item('t_file','main',baz_id,'baz',qux_id,'qux')
		assert_instance_of(
			Sofa::File,
			item,
			'File#commit should commit the attachment file item'
		)
		assert_equal(
			@file.read,
			item.body,
			'File#commit should store the body of the attachment file item'
		)

		# delete the attachment
		sd = Sofa::Set::Static::Folder.root.item('t_file','main')
		sd.update(
			baz_id => {
				'baz' => {
					qux_id => {:action => :delete},
				}
			}
		)
		sd.commit :persistent

		assert_equal(
			{},
			Sofa::Set::Static::Folder.root.item('t_file','main',baz_id,'baz').storage.val,
			'File#commit should delete the body of the attachment file item'
		)
	end

end
