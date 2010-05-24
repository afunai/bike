# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Sofa::Workflow::Register < Sofa::Workflow

	DEFAULT_META = {
		:p_size     => 0,
		:conds      => {:p => '1'},
		:order      => 'id',
		:item_label => Sofa::I18n.n_('item','items',1),
	}

	DEFAULT_SUB_ITEMS = {
		'_owner'     => {:klass => 'meta-owner'},
		'_timestamp' => {:klass => 'meta-timestamp'},
	}

	PERM = {
		:create => 0b1101,
		:read   => 0b1110,
		:update => 0b1110,
		:delete => 0b1110,
	}

end
