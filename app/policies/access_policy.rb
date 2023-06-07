# frozen_string_literal: true

# Access policy setting
class AccessPolicy
  include AccessGranted::Policy

  def configure
    common_model = [
      Household,
      Parishioner,
      Baptism
    ]

    role :admin, proc { |user| user.is_admin? } do
      # User feature
      can %i[read create update], User

      can [:destroy], User do |target_user, _user|
        !target_user.is_admin
      end

      # Common feature
      common_model.each { |model| can :manage, model }
    end

    role :modulator, proc { |user| user.is_modulator } do
      # User feature
      can :read, User

      # Common feature
      common_model.each { |model| can :manage, model }
    end

    role :member, proc { |user| !user.nil? } do
      # Common feature
      common_model.each { |model| can :read, model }
    end
  end
end
