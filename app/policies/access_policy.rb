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

    # The most important role should be at the top.
    # In this case an administrator.
    role :admin, proc { |user| user.is_admin? } do
      can [:read, :create, :update], User

      can [:destroy], User do |target_user, user|
        !target_user.is_admin
      end
    end

    role :modulator, proc {|user| user.is_modulator} do
      can :read, User
    end

    # More privileged role, applies to registered users.
    # role :member, proc { |user| user.registered? } do
    #   can :create, Post
    #   can :create, Comment
    #   can [:update, :destroy], Post do |post, user|
    #     post.author == user
    #   end
    # end
  end
end
