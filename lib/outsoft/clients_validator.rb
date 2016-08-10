module Outsoft
  class ClientsValidator < ParamsValidator
    def validate(record)
      record.predefined.each do  |k, v|
        check_data("#{k}", k, v, record.errors)
      end

      check_extra record.extra, record.errors
    end

    def check_extra extra, errors
      errors[:extra] = 'must be an Array' unless extra.is_a? Array

      extra.each do |i|
        unless i.size == 2
          errors[:extra] = 'must have 2 elements'
        end

        check_string 'extra', 'extra', i[0], errors
        check_string 'extra', 'extra', i[1], errors
      end
    end
  end
end
