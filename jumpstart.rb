# based on bort.rb

puts "========================="
puts "Specify the Project Name:"
$__PROJECT_NAME__ = gets.chomp

plugin 'rspec-on-rails-matchers', 
  :git => 'git://github.com/joshknowles/rspec-on-rails-matchers.git'
plugin 'rspec_expectation_matchers',
  :git => "git://github.com/cyx/rspec_expectation_matchers.git"
plugin 'auto_migrations',
  :git => 'git://github.com/pjhyett/auto_migrations.git'
plugin 'hoptoad_notifier', 
  :git => 'git://github.com/thoughtbot/hoptoad_notifier.git'
plugin 'asset_packager', 
  :git => 'http://synthesis.sbecker.net/pages/asset_packager'
plugin 'limerick_rake', 
  :git => "git://github.com/thoughtbot/limerick_rake.git"
plugin 'jrails',
  :git => 'git://github.com/aaronchi/jrails.git'

gems = %w(will_paginate aasm authlogic rack haml fastercsv faker)

gems.each do |g|
  gem g
end

file '.gems', gems.join("\n")

#==================
# CONFIGURATIONS
#==================
file 'config/environments/test.rb', %q{
# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false
config.action_view.cache_template_loading            = true

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# Use SQL instead of Active Record's schema dumper when creating the test database.
# This is necessary if your schema can't be completely dumped by the schema dumper,
# like if you have constraints or database-specific column types
# config.active_record.schema_format = :sql
  
config.gem 'rspec', :lib => false
config.gem 'rspec-rails', :lib => false

config.gem 'factory_girl', :lib => false
config.gem 'cucumber', :lib => false
config.gem 'webrat', :lib => false
config.gem 'email_spec'
}  

file 'config/environments/staging.rb', 
%q{# Settings specified here will take precedence over those in config/environment.rb

# We'd like to stay as close to prod as possible
# Code is not reloaded between requests
config.cache_classes = true

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Disable delivery errors if you bad email addresses should just be ignored
config.action_mailer.raise_delivery_errors = false
}

#==================
# APPLICATION
#==================

file 'app/controllers/application_controller.rb', 
%q{class ApplicationController < ActionController::Base

  helper :all

  protect_from_forgery

  include HoptoadNotifier::Catcher

end
}

file 'app/views/layouts/application.html.haml', 
%q{!!! Strict
%html(xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en")
  %head
    %meta(http-equiv="Content-type" content="text/html; charset=utf-8")/ 
    %title= AppConfig.site_name
    = stylesheet_link_tag 'screen', :media => 'all', :cache => true %>
    = javascript_include_tag :defaults, :cache => true

  %body{ :class => body_class }
    = render :partial => 'layouts/flashes'
    = yield
}


file 'app/helpers/application_helper.rb', 
%q{module ApplicationHelper
  def body_class
    "#{controller.controller_name} #{controller.controller_name}-#{controller.action_name}"
  end
end
}

file 'app/views/layouts/_flashes.html.haml', 
%q{
%div#flash
  - flash.each do |key, value|
    %div{ :id => "flash_#{key}" }=h value
}


#====================
# INITIALIZERS
#====================
initializer 'hoptoad.rb',
%q{
HoptoadNotifier.configure do |config|
  config.api_key = '1234567890abcdef'
end
}

initializer 'errors.rb', 
%q{# Example:
#   begin
#     some http call
#   rescue *HTTP_ERRORS => error
#     notify_hoptoad error
#   end
require 'net/smtp'

HTTP_ERRORS = [Timeout::Error,
               Errno::EINVAL,
               Errno::ECONNRESET,
               EOFError,
               Net::HTTPBadResponse,
               Net::HTTPHeaderSyntaxError,
               Net::ProtocolError]

SMTP_SERVER_ERRORS = [TimeoutError,
                      IOError,
                      Net::SMTPUnknownError,
                      Net::SMTPServerBusy,
                      Net::SMTPAuthenticationError]

SMTP_CLIENT_ERRORS = [Net::SMTPFatalError,
                      Net::SMTPSyntaxError]

SMTP_ERRORS = SMTP_SERVER_ERRORS + SMTP_CLIENT_ERRORS
}

initializer 'time_formats.rb', 
%q{# Example time formats
{ :short_date => "%x", :long_date => "%a, %b %d, %Y" }.each do |k, v|
  ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.update(k => v)
end
}

file "config/app_config.yml", %{
defaults: &defaults
  site_name: #{$__PROJECT_NAME__}

  mailer:
    from: "noreply@#{$__PROJECT_NAME__.downcase.gsub('_', '-')}.com"
      
development:
  <<: *defaults

test:
  <<: *defaults

staging:
  <<: *defaults

production:
  <<: *defaults
}

envline = "require File.join(File.dirname(__FILE__), 'boot')"
envrb = File.read('config/environment.rb')
envrb.gsub!(envline, envline + '

require "ostruct"
AppConfig = OpenStruct.new(
  YAML.load_file("#{RAILS_ROOT}/config/app_config.yml")[RAILS_ENV]
)
            
')

file 'config/environment.rb', envrb

#==================
# DATABASE
#==================
file 'db/schema.rb', 
%q{
ActiveRecord::Schema.define(:version => 20091207131851) do
  create_table "schema_migrations", :force => true, :id => false do |t|
    t.string   "version"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end
}


file 'config/database.yml', %{
development:
  adapter: mysql
  database: #{$__PROJECT_NAME__}_development
  username: root
  password:
  host: localhost
  encoding: utf8
  
test:
  adapter: mysql
  database: #{$__PROJECT_NAME__}_test
  username: root
  password:
  host: localhost
  encoding: utf8
  
staging:
  adapter: mysql
  database: #{$__PROJECT_NAME__}_staging
  username: root
  password: 
  host: localhost
  encoding: utf8
  socket: /var/lib/mysql/mysql.sock
  
production:
  adapter: mysql
  database: #{$__PROJECT_NAME__}_production
  username: root
  password: 
  host: localhost
  encoding: utf8
  socket: /var/lib/mysql/mysql.sock
}

# ====================
# FINALIZE
# ====================
file '.gitignore', %q{
.DS_Store
log/*.log
log/*.log*
tmp/**/*
tmp/*
config/database.yml
db/*.sqlite3
coverage
solr/**/*
}
run "rm -rf test"
run "rm public/index.html"
run "touch public/stylesheets/screen.css"
run 'find . \( -type d -empty \) -and \( -not -regex ./\.git.* \) -exec touch {}/.gitignore \;'

generate("session", "user_session")
generate("rspec")

rake("db:create")
rake("db:auto:migrate")

rake("jrails:js:scrub")
rake("jrails:js:install")

