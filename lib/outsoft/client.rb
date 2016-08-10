module Outsoft
  class Client < ActiveRecord::Base
    include ActiveModel::Validations

    validates_with ClientsValidator
  end
end
