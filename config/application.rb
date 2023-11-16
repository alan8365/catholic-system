# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Catholic
  # Application setting
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.i18n.default_locale = :zh_tw
  end
end

module Rswag
  module Ui
    # Use for CSP setting
    module CSP
      def call(env)
        _, headers, = response = super
        headers['Content-Security-Policy'] = <<~POLICY.gsub "\n", ' '
          default-src 'self';
          img-src 'self' data: * blob:;
          font-src 'self' https://fonts.gstatic.com;
          style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
          script-src 'self' 'unsafe-inline' 'unsafe-eval';
        POLICY
        response
      end
    end
  end
end

Rswag::Ui::Middleware.prepend Rswag::Ui::CSP
