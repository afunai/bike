# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Set_Dynamic < Test::Unit::TestCase

	def setup
		@sd = Sofa::Set::Dynamic.new(
			:id        => 'foo',
			:klass     => 'set-dynamic',
			:workflow  => 'blog',
			:group     => ['roy','don'],
			:tmpl      => <<'_tmpl'.chomp,
<ul id="foo" class="sofa-blog">
$()</ul>
$(.submit)
_tmpl
			:item_arg  => Sofa::Parser.parse_html(<<'_html')
	<li>name:(text 32 :'nobody'): comment:(text 64 :'hi.')</li>
_html
		)
		@sd[:tmpl_action_create] = ''
		def @sd._g_submit(arg)
			"[#{my[:id]}-#{arg[:orig_action]}]\n"
		end
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

	def test_meta_tid
		tid = @sd[:tid]
		assert_match(
			Sofa::REX::TID,
			tid,
			'Set::Dynamic#meta_tid should return an unique id per an instance'
		)
		assert_equal(
			tid,
			@sd[:tid],
			'Set::Dynamic#meta_tid should return the same id throughout the lifecycle of the item'
		)
		assert_not_equal(
			tid,
			Sofa::Set::Dynamic.new[:tid],
			'Set::Dynamic#meta_tid should be unique to an item'
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
		@sd[:tmpl_navi] = ''
		@sd.each {|item| item[:tmpl_action_update] = '' }
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
				def item._g_update(arg)
					'moo!'
				end
			}
		}
		assert_equal(
			<<'_html',
<ul id="foo" class="sofa-blog">
	<li>moo!: moo!</li>
</ul>
[foo-update]
_html
			@sd.get(:conds => {:id => '1235'},:action => :update),
			'Set::Dynamic#get should pass the given action to lower items'
		)
	end

	def test_get_create
		@sd.load(
			'1234' => {'name' => 'frank','comment' => 'bar'},
			'1235' => {'name' => 'carl', 'comment' => 'baz'}
		)
		result = @sd.get(:action => :create)
		assert_match(
			/<input/,
			result,
			'Set::Dynamic#_g_create should return the _g_create() of a newly created item'
		)
		assert_no_match(
			/bar/,
			result,
			'Set::Dynamic#_g_create should not include the _g_create() of existing items'
		)
	end

	def test_get_by_self_reference
		ss = Sofa::Set::Static.new(
			:html => '<ul class="sofa-attachment"><li class="body"></li>$(.pipco)</ul>'
		)
		sd = ss.item('main')
		def sd._g_submit(arg)
			''
		end
		def sd._g_pipco(arg)
			_get_by_action_tmpl(arg) || 'PIPCO'
		end
		def sd._g_jawaka(arg)
			'JAWAKA'
		end
		sd[:tmpl_navi] = ''

		sd[:tmpl_pipco]  = '<foo>$(.jawaka)</foo>'
		sd[:tmpl_jawaka] = nil
		assert_equal(
			'<ul class="sofa-attachment"><foo>JAWAKA</foo></ul>',
			ss.get(:action => :pipco),
			'Set::Dynamic#_get_by_self_reference should work via [:parent]._get_by_tmpl()'
		)

		sd[:tmpl_pipco]  = '<foo>$(.jawaka)</foo>'
		sd[:tmpl_jawaka] = 'via tmpl'
		assert_equal(
			'<ul class="sofa-attachment"><foo>JAWAKA</foo></ul>',
			ss.get(:action => :pipco),
			'Set::Dynamic#_get_by_self_reference should not recur'
		)

		sd[:tmpl_pipco]  = '<foo>$(.pipco)</foo>'
		sd[:tmpl_jawaka] = nil
		assert_nothing_raised(
			'Set::Dynamic#_get_by_self_reference should not cause an infinite reference'
		) {
			ss.get(:action => :pipco)
		}

		sd[:tmpl_pipco]  = '<foo>$()</foo>'
		assert_nothing_raised(
			'Set::Dynamic#_get_by_self_reference should not cause an infinite reference'
		) {
			ss.get(:action => :pipco)
		}

		sd[:tmpl_pipco]  = '<foo>$(.jawaka)</foo>'
		sd[:tmpl_jawaka] = '<bar>$(.pipco)</bar>'
		assert_nothing_raised(
			'Set::Dynamic#_get_by_self_reference should not cause an infinite reference'
		) {
			ss.get(:action => :pipco)
		}
	end

	def test_get_by_self_reference_multiple_vars
		ss = Sofa::Set::Static.new(
			:html => '<ul class="sofa-attachment">$(.pipco)<li class="body">foo:(text)</li></ul>'
		)
		sd = ss.item('main')
		def sd._g_pipco(arg)
			'PIPCO'
		end
		sd[:tmpl_navi] = ''

		assert_equal(
			'<ul class="sofa-attachment">PIPCO</ul>',
			ss.get(:action => :pipco),
			'Set::Dynamic#_get_by_self_reference should not be affected by previous $(.action)'
		)
	end

	def test_get_uri_prev_next
		@sd[:p_size] = 2
		@sd.load(
			'20091128_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091129_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091130_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091201_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091202_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091203_0001' => {'name' => 'frank','comment' => 'bar'}
		)

		assert_equal(
			'200912/p=1/',
			@sd.send(
				:_g_uri_prev,
				:conds => {:d => '200912',:p => '2'}
			),
			'Set::Dynamic#_g_uri_prev should return the previous uri for the given conds'
		)
		assert_nil(
			@sd.send(
				:_g_uri_next,
				:conds => {:d => '200912',:p => '2'}
			),
			'Set::Dynamic#_g_uri_next should return nil if there is no next conds'
		)

		assert_equal(
			'200911/p=2/',
			@sd.send(
				:_g_uri_prev,
				:conds => {:d => '200912',:p => '1'}
			),
			'Set::Dynamic#_g_uri_prev should return the previous uri for the given conds'
		)
		assert_equal(
			'200911/p=1/',
			@sd.send(
				:_g_uri_prev,
				:conds => {:d => '200911',:p => '2'}
			),
			'Set::Dynamic#_g_uri_prev should return the previous uri for the given conds'
		)
		assert_equal(
			'200912/p=1/',
			@sd.send(
				:_g_uri_next,
				:conds => {:d => '200911',:p => '2'}
			),
			'Set::Dynamic#_g_uri_next should return the next uri for the given conds'
		)
		assert_nil(
			@sd.send(
				:_g_uri_prev,
				:conds => {:d => '200911',:p => '1'}
			),
			'Set::Dynamic#_g_uri_prev should return nil if there is no previous conds'
		)

		@sd[:tmpl_navi] = '$(.uri_prev)'
		assert_equal(
			'200911/p=1/',
			@sd.send(
				:_get_by_self_reference,
				:action      => :navi,
				:conds       => {:d => '200911',:p => '2'},
				:orig_action => :read
			),
			'Set::Dynamic#_g_navi should pass the conds to the subsequent calls to _g_*()'
		)
	end

	def test_recurring_action_tmpl
		@sd.load(
			'20091128_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091129_0001' => {'name' => 'frank','comment' => 'bar'}
		)
		@sd[:tmpl_navi] = '$(.navi)'

		result = nil
		assert_nothing_raised(
			'Set::Dynamic#_g_navi should not call itself recursively'
		) {
			result = @sd.send(
				:_get_by_self_reference,
				:action      => :navi,
				:conds       => {:d => '20091128'},
				:orig_action => :read
			)
		}
		assert_equal(
			'$(.navi)',
			result,
			'Set::Dynamic#_g_navi should ignore $(.navi)'
		)

		@sd[:tmpl_navi] = nil
		@sd[:tmpl_navi_next] = '$(.navi)'
		assert_nothing_raised(
			'Set::Dynamic#_g_navi should not call itself recursively'
		) {
			result = @sd.send(
				:_get_by_self_reference,
				:action      => :navi,
				:conds       => {:d => '20091128'},
				:orig_action => :read
			)
		}
		assert_match(
			/\$\(\.navi\)/,
			result,
			'Set::Dynamic#_g_navi_next should ignore $(.navi)'
		)
	end

	def test_uri_p
		@sd.load(
			'20091128_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091129_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091130_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091201_0001' => {'name' => 'frank','comment' => 'bar'}
		)

		@sd[:p_size] = 2
		assert_equal(
			['200911/p=1/','200911/p=2/'],
			@sd.send(
				:_uri_p,
				:conds => {:d => '200911',:p => '1'}
			),
			'Set::Dynamic#_uri_p should return the array of the sibling conds'
		)

		@sd[:p_size] = nil
		assert_nil(
			@sd.send(
				:_uri_p,
				:conds => {:d => '200911'}
			),
			'Set::Dynamic#_uri_p should return nil if the siblings are not :p'
		)

		@sd[:p_size] = 2
		assert_nil(
			@sd.send(
				:_uri_p,
				:conds => {:d => '200911',:id => '20091129_0001'}
			),
			'Set::Dynamic#_uri_p should return nil if the siblings are not :p'
		)
		assert_nil(
			@sd.send(
				:_uri_p,
				:conds => {:d => '200911',:p => '1',:id => '20091129_0001'}
			),
			'Set::Dynamic#_uri_p should return nil if the siblings are not :p'
		)
	end

	def test_g_view_ym
		@sd.load(
			'20091128_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091129_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091130_0001' => {'name' => 'frank','comment' => 'bar'},
			'20091201_0001' => {'name' => 'frank','comment' => 'bar'},
			'20100111_0001' => {'name' => 'frank','comment' => 'bar'}
		)
		assert_equal(
			<<'_html',
<div class="view_ym">
	<span class="y">
		2009 |
		<span class="m"><a href="/foo/200911/">11</a></span>
		<span class="m"><a href="/foo/200912/">12</a></span>
		<br/>
	</span>
	<span class="y">
		2010 |
		<span class="m"><a href="/foo/201001/">01</a></span>
		<br/>
	</span>
</div>
_html
			@sd.send(
				:_g_view_ym,
				{:conds => {}}
			),
			'Set::Dynamic#_g_view_ym should return the available ym conds'
		)

		assert_equal(
			<<'_html',
<div class="view_ym">
	<span class="y">
		2009 |
		<span class="m"><a href="/foo/200911/">11</a></span>
		<span class="m"><span class="current">12</span></span>
		<br/>
	</span>
	<span class="y">
		2010 |
		<span class="m"><a href="/foo/201001/">01</a></span>
		<br/>
	</span>
</div>
_html
			@sd.send(
				:_g_view_ym,
				{:conds => {:d => '200912'}}
			),
			'Set::Dynamic#_g_view_ym should distinguish the current cond[:d] if available'
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
		s = @sd.storage
		def s.new_id
			@c ||= 0
			(@c += 1).to_s
		end

		@sd.create({})
		assert_equal(
			{},
			@sd.val,
			'Set::Dynamic#create should build the empty storage by default'
		)

		@sd.create('_1235' => {'name' => 'carl'})
		assert_equal(
			{'name' => 'carl','comment' => 'hi.'},
			@sd.item('_1235').val,
			'Set::Dynamic#create should create the new items in the empty storage'
		)
		@sd.commit
		assert_equal(
			{'1' => {'name' => 'carl','comment' => 'hi.'}},
			@sd.val,
			'Set::Dynamic#create should create the new items in the empty storage'
		)

		@sd.create('_1234' => {'name' => 'frank'})
		assert_equal(
			{'name' => 'frank','comment' => 'hi.'},
			@sd.item('_1234').val,
			'Set::Dynamic#create should create the new items in the empty storage'
		)
		assert_equal(
			{},
			@sd.val,
			'Set::Dynamic#val should be empty before the commit'
		)
		@sd.commit
		assert_equal(
			{'2' => {'name' => 'frank','comment' => 'hi.'}},
			@sd.val,
			'Set::Dynamic#create should overwrite all items in the storage'
		)

		@sd.create('_2' => {'name' => 'frank'},'_1' => {'name' => 'bobby'})
		assert_equal(
			{},
			@sd.val,
			'Set::Dynamic#val should be empty before the commit'
		)
		@sd.commit
		assert_equal(
			{
				'4' => {'name' => 'frank','comment' => 'hi.'},
				'3' => {'name' => 'bobby','comment' => 'hi.'},
			},
			@sd.val,
			'Set::Dynamic#create should create multiple items in the empty storage'
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
		@sd.update('20091122_1235' => {:action => :delete})
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
		assert_nil(
			@sd.result,
			'Set::Dynamic#result should return nil before the commit'
		)
		assert_equal(
			{
				'20091122_1234' => {'name' => 'frank','comment' => 'bar'},
				'20091122_1235' => {'name' => 'carl', 'comment' => 'baz'},
			},
			@sd.val,
			'Set::Dynamic#update should not touch the original values in the storage'
		)

		@sd.commit :temp

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
			{
				'20091122_1234' => @sd.item('20091122_1234'),
				'20091122_1235' => @sd.instance_eval { @item_object['20091122_1235'] },
				'_1236'         => @sd.item('_1236'),
			},
			@sd.result,
			'Set::Dynamic#result should return a hash of the committed items when :update'
		) if nil
		assert_equal(
			{'comment' => @sd.item('20091122_1234','comment')},
			@sd.item('20091122_1234').result,
			'Set::Static#result should return a hash of the committed items when :update'
		)
		assert_equal(
			:delete,
			@sd.result['20091122_1235'].result,
			'Set::Static#result should return the committed action unless :update'
		)
		assert_equal(
			:create,
			@sd.item('_1236').result,
			'Set::Static#result should return the committed action unless :update'
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
			@sd.update('20091122_0001' => {:action => :delete})
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
			@sd.update('20091122_0001' => {:action => :delete})
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
			@sd.update('20091122_0001' => {:action => :delete})
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
			@sd.update('20091122_0001' => {:action => :delete})
		}
		assert_nothing_raised(
			"frank should be able to delete carl's item"
		) {
			@sd.update('20091122_0002' => {:action => :delete})
		}
	end

end
