# frozen_string_literal: true

class PostcodeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.blank?
      record.errors.add(attribute, :blank) unless options[:allow_blank]
    elsif value.nil?
      record.errors.add(attribute, :blank) unless options[:allow_nil]
    else
      postcode = UKPostcode.parse(value.to_s)

      unless postcode.full_valid?
        record.errors.add(attribute, "Enter a valid postcode, such as SW1A 1AA")
      end
    end
  end
end
