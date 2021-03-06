# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Bike::Workflow::Forum < Bike::Workflow

  DEFAULT_META = {
    :conds      => {:p => 'last'},
    :p_size     => 10,
    :item_label => Bike::I18n.n_('post', 'posts', 1),
  }

  DEFAULT_SUB_ITEMS = {
    '_owner'     => {:klass => 'meta-owner'},
    '_timestamp' => {:klass => 'meta-timestamp'},
  }

  PERM = {
    :create => 0b11110,
    :read   => 0b11111,
    :update => 0b11000,
    :delete => 0b11000,
  }

end
