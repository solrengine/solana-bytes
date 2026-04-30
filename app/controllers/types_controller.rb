class TypesController < ApplicationController
  def index
    @groups = AccountTaxonomy.all
  end
end
