# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.0.4', '>= 7.0.4.3'

# Use sqlite3 as the database for Active Record
gem 'sqlite3', '~> 1.4'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 5.0'

# JSON Web Token [https://github.com/jwt/ruby-jwt]
gem 'jwt'

# Swagger api [https://github.com/rswag/rswag]
gem 'rswag-api'
gem 'rswag-ui'

# xlsx file processing [https://github.com/randym/axlsx]
gem 'axlsx', '~> 2.0', '>= 2.0.1'

group :development, :test do
  gem 'rspec-rails'
  gem 'rswag-specs'
  gem 'rubocop', require: false
end

# Access Granted [https://github.com/chaps-io/access-granted]
gem 'access-granted', '~> 1.3'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem 'bcrypt', '~> 3.1.7'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

# Use for full text search [https://github.com/sunspot/sunspot]
gem 'sunspot_rails'

# Use RMagick for image processing [https://github.com/rmagick/rmagick]
gem 'rmagick'

# Use docx file processing [https://github.com/adamalbrecht/docx_replace]
# gem 'docx_replace', '~> 1.2'
gem 'docx_replace', '~> 1.1'

# Use prawn for pdf [https://github.com/prawnpdf/prawn]
gem 'matrix'
gem 'prawn'

gem 'zip-zip'

# Use will_paginate for pagination [https://github.com/mislav/will_paginate]
gem 'will_paginate', '~> 4.0'


group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri mingw x64_mingw]

  gem 'sunspot_solr' # optional pre-packaged Solr distribution for use in development. Not for use in production.
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"
