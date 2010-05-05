# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Workflow::Enquete < Sofa::Workflow

	DEFAULT_META = {
		:p_size => 10,
		:conds  => {:p => 'last'},
	}

	DEFAULT_SUB_ITEMS = {}

	PERM = {
		:create => 0b0001,
		:read   => 0b1100,
		:update => 0b0000,
		:delete => 0b1100,
	}

end