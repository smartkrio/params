module Outsoft
  class Param < ActiveRecord::Base
    include ActiveModel::Validations

    validates :name, presence:true
    validates_with ParamsValidator
    validates :company_id, allow_blank: true, numericality: true

    def self.default_value type
      ParamsValidator.value_types[type] rescue nil
    end
  end
end
