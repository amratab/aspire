class User < ApplicationRecord
  require 'securerandom'

  has_secure_password

  enum role: { customer: 0, admin: 1 }

  has_many :loans
  validates_uniqueness_of :email
  validates :email, presence: true
  validates_presence_of :first_name, :last_name
end
