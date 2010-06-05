# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Runo::Workflow::Contact < Runo::Workflow

	DEFAULT_META = {
		:p_size     => 10,
		:conds      => {:p => 'last'},
		:item_label => Runo::I18n.n_('item','items',1),
	}

	DEFAULT_SUB_ITEMS = {}

	PERM = {
		:create => 0b0001,
		:read   => 0b1100,
		:update => 0b0000,
		:delete => 0b1100,
	}

end
