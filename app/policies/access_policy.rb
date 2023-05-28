class AccessPolicy
  include AccessGranted::Policy

  def configure
    # Example policy for AccessGranted.
    # For more details check the README at
    #
    # https://github.com/chaps-io/access-granted/blob/master/README.md
    #
    # Roles inherit from less important roles, so:
    # - :admin has permissions defined in :member, :guest and himself
    # - :member has permissions from :guest and himself
    # - :guest has only its own permissions since it's the first role.
    common_model = [
      Household,
      Parishioner,
    ]

    role :admin, proc { |user| user.is_admin? } do
      # User feature
      can [:read, :create, :update], User

      can [:destroy], User do |target_user, user|
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
