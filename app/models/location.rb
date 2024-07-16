# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id         :bigint           not null, primary key
#  address    :text
#  county     :text
#  locality   :text
#  name       :text
#  postcode   :text
#  town       :text
#  url        :text
#  urn        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_locations_on_urn  (urn) UNIQUE
#
class Location < ApplicationRecord
  audited

  has_many :sessions
  has_many :patients
  has_many :consent_forms, through: :sessions

  validates :name, presence: true
  validates :urn, presence: true, uniqueness: true
end
