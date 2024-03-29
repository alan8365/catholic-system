# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  # User does not need avatar, but maybe can use in image upload
  # mount_uploader :avatar, AvatarUploader
  validates :username, presence: true, uniqueness: true
  validates :name, presence: true
  validates :password,
            length: { minimum: 6 },
            if: -> { new_record? || !password.nil? }
end
