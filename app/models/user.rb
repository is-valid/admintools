class User < ActiveRecord::Base
  attr_accessible :email, :first_name, :info, :last_name, :skype

  has_one  :desktop
  has_many :devices
  has_one  :room
  
  validates :first_name, :presence => true
  validates :last_name,  :presence => true
  validates :email,      :presence => true, :uniqueness => true
  validates :skype,      :presence => true
end