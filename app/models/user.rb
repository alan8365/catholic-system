class User < ApplicationRecord
  has_secure_password
  # User does not need avatar, but maybe can use in image upload
  # mount_uploader :avatar, AvatarUploader
  # validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: true
  validates :password,
            length: { minimum: 6 },
            if: -> { new_record? || !password.nil? }
end