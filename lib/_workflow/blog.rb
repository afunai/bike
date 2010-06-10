# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Runo::Workflow::Blog < Runo::Workflow

	DEFAULT_META = {
		:p_size     => 10,
		:conds      => {:d => '999999',:p => 'last'},
		:order      => '-id',
		:item_label => Runo::I18n.n_('entry','entries',1),
	}

	DEFAULT_SUB_ITEMS = {
		'_owner'     => {:klass => 'meta-owner'},
		'_group'     => {:klass => 'meta-group'},
		'_timestamp' => {:klass => 'meta-timestamp'},
	}

	PERM = {
		:create => 0b1100,
		:read   => 0b1111,
		:update => 0b1010,
		:delete => 0b1010,
	}

end