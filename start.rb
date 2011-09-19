initializer 'generators.rb', <<-RUBY
Rails.application.config.generators do |g|
end
RUBY
#"mongoid",
@recipes = ["jquery", "haml", "rspec", "cucumber", "guard",  "action_mailer", "devise", "cancan", "add_user", "rails_admin", "home_page", "home_page_users", "users_page", "css_setup", "application_layout", "html5", "navigation", "cleanup", "ban_spiders", "mailer", "sitemap", "extras", "seed_database", "capistrano", "git"]

def recipes; @recipes end
def recipe?(name); @recipes.include?(name) end

def say_custom(tag, text); say "\033[1m\033[36m" + tag.to_s.rjust(10) + "\033[0m" + "  #{text}" end
def say_recipe(name); say "\033[1m\033[36m" + "recipe".rjust(10) + "\033[0m" + "  Running #{name} recipe..." end
def say_wizard(text); say_custom(@current_recipe || 'wizard', text) end

def ask_wizard(question)
  ask "\033[1m\033[30m\033[46m" + (@current_recipe || "prompt").rjust(10) + "\033[0m\033[36m" + "  #{question}\033[0m"
end

def yes_wizard?(question)
  answer = ask_wizard(question + " \033[33m(y/n)\033[0m")
  case answer.downcase
    when "yes", "y"
      true
    when "no", "n"
      false
    else
      yes_wizard?(question)
  end
end

def no_wizard?(question); !yes_wizard?(question) end

def multiple_choice(question, choices)
  say_custom('question', question)
  values = {}
  choices.each_with_index do |choice,i| 
    values[(i + 1).to_s] = choice[1]
    say_custom (i + 1).to_s + ')', choice[0]
  end
  answer = ask_wizard("Enter your selection:") while !values.keys.include?(answer)
  values[answer]
end

@current_recipe = nil
@configs = {}

@after_blocks = []
def after_bundler(&block); @after_blocks << [@current_recipe, block]; end
@after_everything_blocks = []
def after_everything(&block); @after_everything_blocks << [@current_recipe, block]; end
@before_configs = {}
def before_config(&block); @before_configs[@current_recipe] = block; end


case Rails::VERSION::MAJOR.to_s
when "3"
  case Rails::VERSION::MINOR.to_s
  when "1"
    say_wizard "You are using Rails version #{Rails::VERSION::STRING}."
    @recipes << 'rails 3.1'
  when "0"
    say_wizard "You are using Rails version #{Rails::VERSION::STRING}."
    @recipes << 'rails 3.0'
  else
    say_wizard "You are using Rails version #{Rails::VERSION::STRING} which is not supported."
  end
else
  say_wizard "You are using Rails version #{Rails::VERSION::STRING} which is not supported."
end

# show which version of rake is running
# with the added benefit of ensuring that the Gemfile's version of rake is activated
gemfile_rake_ver = run 'bundle exec rake --version', :capture => true, :verbose => false
say_wizard "You are using #{gemfile_rake_ver.strip}"

say_wizard "Checking configuration. Please confirm your preferences."

# >---------------------------[ Javascript Runtime ]-----------------------------<

prepend_file 'Gemfile' do <<-RUBY
require 'rbconfig'
HOST_OS = Config::CONFIG['host_os']

RUBY
end

if recipes.include? 'rails 3.1'
  append_file 'Gemfile' do <<-RUBY
# install a Javascript runtime for linux
if HOST_OS =~ /linux/i
  gem 'therubyracer', '>= 0.8.2'
end

  RUBY
  end
end

# >---------------------------------[ Recipes ]----------------------------------<


# >--------------------------------[ jQuery ]---------------------------------<

@current_recipe = "jquery"
@before_configs["jquery"].call if @before_configs["jquery"]
say_recipe 'jQuery'

config = {}
config['jquery'] = yes_wizard?("Would you like to use jQuery?") if true && true unless config.key?('jquery')
config['ui'] = yes_wizard?("Would you like to use jQuery UI?") if true && true unless config.key?('ui')
@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/jquery.rb

if config['jquery']
  if recipes.include? 'rails 3.0'
    say_wizard "Replacing Prototype framework with jQuery for Rails 3.0."
    after_bundler do
      say_wizard "jQuery recipe running 'after bundler'"
      # remove the Prototype adapter file
      remove_file 'public/javascripts/rails.js'
      # remove the Prototype files (if they exist)
      remove_file 'public/javascripts/controls.js'
      remove_file 'public/javascripts/dragdrop.js'
      remove_file 'public/javascripts/effects.js'
      remove_file 'public/javascripts/prototype.js'
      # add jQuery files
      inside "public/javascripts" do
        get "https://raw.github.com/rails/jquery-ujs/master/src/rails.js", "rails.js"
        get "http://code.jquery.com/jquery-1.6.min.js", "jquery.js"
        if config['ui']
          get "https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.12/jquery-ui.min.js", "jqueryui.js"
        end
      end
      # adjust the Javascript defaults
      # first uncomment "config.action_view.javascript_expansions"
      gsub_file "config/application.rb", /# config.action_view.javascript_expansions/, "config.action_view.javascript_expansions"
      # then add "jquery rails" if necessary
      gsub_file "config/application.rb", /= \%w\(\)/, "= %w(jquery rails)"
      # finally change to "jquery jqueryui rails" if necessary
      if config['ui']
        gsub_file "config/application.rb", /jquery rails/, "jquery jqueryui rails"
      end
    end
  elsif recipes.include? 'rails 3.1'
    if config['ui']
      inside "app/assets/javascripts" do
        get "https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.12/jquery-ui.min.js", "jqueryui.js"
      end
    else
      say_wizard "jQuery installed by default in Rails 3.1."
    end
  else
    say_wizard "Don't know what to do for Rails version #{Rails::VERSION::STRING}. jQuery recipe skipped."
  end
else
  if config['ui']
    say_wizard "You said you didn't want jQuery. Can't install jQuery UI without jQuery."
  end
  recipes.delete('jquery')
end


# >---------------------------------[ HAML ]----------------------------------<

@current_recipe = "haml"
@before_configs["haml"].call if @before_configs["haml"]
say_recipe 'HAML'

config = {}
config['haml'] = yes_wizard?("Would you like to use Haml instead of ERB?") if true && true unless config.key?('haml')
@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/haml.rb

if config['haml']
  if recipes.include? 'rails 3.0'
    # for Rails 3.0, use only gem versions we know that work
    gem 'haml', '3.1.1'
    gem 'haml-rails', '0.3.4', :group => :development
  else
    # for Rails 3.1+, use optimistic versioning for gems
    gem 'haml', '>= 3.1.2'
    gem 'haml-rails', '>= 0.3.4', :group => :development
  end
else
  recipes.delete('haml')
end


# >---------------------------------[ RSpec ]---------------------------------<

@current_recipe = "rspec"
@before_configs["rspec"].call if @before_configs["rspec"]
say_recipe 'RSpec'

config = {}
config['rspec'] = yes_wizard?("Would you like to use RSpec instead of TestUnit?") if true && true unless config.key?('rspec')
config['factory_girl'] = yes_wizard?("Would you like to use factory_girl for test fixtures with RSpec?") if true && true unless config.key?('factory_girl')
@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/rspec.rb

if config['rspec']
  if recipes.include? 'rails 3.0'
    # for Rails 3.0, use only gem versions we know that work
    say_wizard "REMINDER: When creating a Rails app using RSpec..."
    say_wizard "you should add the '-T' flag to 'rails new'"
    gem 'rspec-rails', '2.6.1', :group => [:development, :test]
    if recipes.include? 'mongoid'
      # use the database_cleaner gem to reset the test database
      gem 'database_cleaner', '0.6.7', :group => :test
      # include RSpec matchers from the mongoid-rspec gem
      gem 'mongoid-rspec', '1.4.2', :group => :test
    end
    if config['factory_girl']
      # use the factory_girl gem for test fixtures
      gem 'factory_girl_rails', '1.1.beta1', :group => :test
    end
  else
    # for Rails 3.1+, use optimistic versioning for gems
    gem 'rspec-rails', '>= 2.6.1', :group => [:development, :test]
    if recipes.include? 'mongoid'
      # use the database_cleaner gem to reset the test database
      gem 'database_cleaner', '>= 0.6.7', :group => :test
      # include RSpec matchers from the mongoid-rspec gem
      gem 'mongoid-rspec', '>= 1.4.4', :group => :test
    end
    if config['factory_girl']
      # use the factory_girl gem for test fixtures
      gem 'factory_girl_rails', '>= 1.2.0', :group => :test
    end
  end
else
  recipes.delete('rspec')
end

# note: there is no need to specify the RSpec generator in the config/application.rb file

if config['rspec']
  after_bundler do
    say_wizard "RSpec recipe running 'after bundler'"
    generate 'rspec:install'

    say_wizard "Removing test folder (not needed for RSpec)"
    run 'rm -rf test/'

    inject_into_file 'config/application.rb', :after => "Rails::Application\n" do <<-RUBY

    # don't generate RSpec tests for views and helpers
    config.generators do |g|
      g.view_specs false
      g.helper_specs false
    end

RUBY
    end


    if recipes.include? 'mongoid'

      # remove ActiveRecord artifacts
      gsub_file 'spec/spec_helper.rb', /config.fixture_path/, '# config.fixture_path'
      gsub_file 'spec/spec_helper.rb', /config.use_transactional_fixtures/, '# config.use_transactional_fixtures'

      # reset your application database to a pristine state during testing
      inject_into_file 'spec/spec_helper.rb', :before => "\nend" do
      <<-RUBY
  \n
  # Clean up the database
  require 'database_cleaner'
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.orm = "mongoid"
  end

  config.before(:each) do
    DatabaseCleaner.clean
  end
RUBY
      end

      # remove either possible occurrence of "require rails/test_unit/railtie"
      gsub_file 'config/application.rb', /require 'rails\/test_unit\/railtie'/, '# require "rails/test_unit/railtie"'
      gsub_file 'config/application.rb', /require "rails\/test_unit\/railtie"/, '# require "rails/test_unit/railtie"'

      # configure RSpec to use matchers from the mongoid-rspec gem
      create_file 'spec/support/mongoid.rb' do 
      <<-RUBY
RSpec.configure do |config|
  config.include Mongoid::Matchers
end
RUBY
      end
    end

    if recipes.include? 'devise'
      # add Devise test helpers
      create_file 'spec/support/devise.rb' do 
      <<-RUBY
RSpec.configure do |config|
  config.include Devise::TestHelpers, :type => :controller
end
RUBY
      end
    end

  end
end


# >-------------------------------[ Cucumber ]--------------------------------<

@current_recipe = "cucumber"
@before_configs["cucumber"].call if @before_configs["cucumber"]
say_recipe 'Cucumber'

config = {}
config['cucumber'] = yes_wizard?("Would you like to use Cucumber for your BDD?") if true && true unless config.key?('cucumber')
@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/cucumber.rb

if config['cucumber']
  if recipes.include? 'rails 3.0'
    # for Rails 3.0, use only gem versions we know that work
    gem 'cucumber-rails', '0.5.1', :group => :test
    gem 'capybara', '1.0.0', :group => :test
    gem 'database_cleaner', '0.6.7', :group => :test
    gem 'launchy', '0.4.0', :group => :test
  else
    # for Rails 3.1+, use optimistic versioning for gems
    gem 'cucumber-rails', '>= 1.0.2', :group => :test
    gem 'capybara', '>= 1.1.1', :group => :test
    gem 'database_cleaner', '>= 0.6.7', :group => :test
    gem 'launchy', '>= 2.0.5', :group => :test
  end
else
  recipes.delete('cucumber')
end

if config['cucumber']
  after_bundler do
    say_wizard "Cucumber recipe running 'after bundler'"
    generate "cucumber:install --capybara#{' --rspec' if recipes.include?('rspec')}#{' -D' if recipes.include?('mongoid')}"
    if recipes.include? 'mongoid'
      gsub_file 'features/support/env.rb', /transaction/, "truncation"
      inject_into_file 'features/support/env.rb', :after => 'begin' do
        "\n  DatabaseCleaner.orm = 'mongoid'"
      end
    end
  end
end

if config['cucumber']
  if recipes.include? 'devise'
    after_bundler do
      say_wizard "Copying Cucumber scenarios from the rails3-devise-rspec-cucumber examples"
      begin
        # copy all the Cucumber scenario files from the rails3-devise-rspec-cucumber example app
        get 'https://raw.github.com/RailsApps/rails3-devise-rspec-cucumber/master/features/users/sign_in.feature', 'features/users/sign_in.feature'
        get 'https://raw.github.com/RailsApps/rails3-devise-rspec-cucumber/master/features/users/sign_out.feature', 'features/users/sign_out.feature'
        get 'https://raw.github.com/RailsApps/rails3-devise-rspec-cucumber/master/features/users/sign_up.feature', 'features/users/sign_up.feature'
        get 'https://raw.github.com/RailsApps/rails3-devise-rspec-cucumber/master/features/users/user_edit.feature', 'features/users/user_edit.feature'
        get 'https://raw.github.com/RailsApps/rails3-devise-rspec-cucumber/master/features/users/user_show.feature', 'features/users/user_show.feature'
        get 'https://raw.github.com/RailsApps/rails3-devise-rspec-cucumber/master/features/step_definitions/user_steps.rb', 'features/step_definitions/user_steps.rb'
        remove_file 'features/support/paths.rb'
        get 'https://raw.github.com/RailsApps/rails3-devise-rspec-cucumber/master/features/support/paths.rb', 'features/support/paths.rb'
      rescue OpenURI::HTTPError
        say_wizard "Unable to obtain Cucumber example files from the repo"
      end
    end
  end
end


# >---------------------------------[ guard ]---------------------------------<

@current_recipe = "guard"
@before_configs["guard"].call if @before_configs["guard"]
say_recipe 'guard'

config = {}
config['guard'] = yes_wizard?("Would you like to use Guard to automate your workflow?") if true && true unless config.key?('guard')
config['livereload'] = yes_wizard?("Would you like to enable the LiveReload guard?") if true && true unless config.key?('livereload')
@configs[@current_recipe] = config

if config['guard']
  gem 'guard', '>= 0.6.2', :group => :development
  
  append_file 'Gemfile' do <<-RUBY
case HOST_OS
  when /darwin/i
    gem 'rb-fsevent', :group => :development
    gem 'growl', :group => :development
  when /linux/i
    gem 'libnotify', :group => :development
    gem 'rb-inotify', :group => :development
  when /mswin|windows/i
    gem 'rb-fchange', :group => :development
    gem 'win32console', :group => :development
    gem 'rb-notifu', :group => :development
end
  RUBY
  end

  def guards
    @guards ||= []
  end

  def guard(name, version = nil)
    args = []
    if version
      args << version 
    end
    args << { :group => :development }
    gem "guard-#{name}", *args
    guards << name
  end

  guard 'bundler', '>= 0.1.3' 

  unless recipes.include? 'pow' 
    guard 'rails', '>= 0.0.3' 
  end

  if config['livereload']
    guard 'livereload', '>= 0.3.0'
  end

  if recipes.include? 'rspec' 
    guard 'rspec', '>= 0.4.3' 
  end

  if recipes.include? 'cucumber' 
    guard 'cucumber', '>= 0.6.1' 
  end

  after_bundler do
    run 'guard init'
    guards.each do |name|
      run "guard init #{name}"
    end
  end

else
  recipes.delete 'guard' 
end


# >--------------------------------[ Mongoid ]--------------------------------<
=begin
@current_recipe = "mongoid"
@before_configs["mongoid"].call if @before_configs["mongoid"]
say_recipe 'Mongoid'

config = {}
config['mongoid'] = yes_wizard?("Would you like to use Mongoid to connect to a MongoDB database?") if true && true unless config.key?('mongoid')
@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/mongoid.rb

if config['mongoid']
  if recipes.include? 'rails 3.0'
    # for Rails 3.0, use only gem versions we know that work
    say_wizard "REMINDER: When creating a Rails app using Mongoid..."
    say_wizard "you should add the '-O' flag to 'rails new'"
    gem 'bson_ext', '1.3.1'
    gem 'mongoid', '2.0.2'
  else
    # for Rails 3.1+, use optimistic versioning for gems
    gem 'bson_ext', '>= 1.3.1'
    gem 'mongoid', '>= 2.2.0'
  end
else
  recipes.delete('mongoid')
end

if config['mongoid']
  after_bundler do
    say_wizard "Mongoid recipe running 'after bundler'"
    # note: the mongoid generator automatically modifies the config/application.rb file
    # to remove the ActiveRecord dependency by commenting out "require active_record/railtie'"
    generate 'mongoid:config'
    # remove the unnecessary 'config/database.yml' file
    remove_file 'config/database.yml'
  end
end
=end


# >-----------------------------[ ActionMailer ]------------------------------<

@current_recipe = "action_mailer"
@before_configs["action_mailer"].call if @before_configs["action_mailer"]
say_recipe 'ActionMailer'


@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/action_mailer.rb

after_bundler do
  say_wizard "ActionMailer recipe running 'after bundler'"
  # modifying environment configuration files for ActionMailer
  gsub_file 'config/environments/development.rb', /# Don't care if the mailer can't send/, '# ActionMailer Config'
  gsub_file 'config/environments/development.rb', /config.action_mailer.raise_delivery_errors = false/ do
  <<-RUBY
config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  # A dummy setup for development - no deliveries, but logged
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default :charset => "utf-8"
RUBY
  end
  gsub_file 'config/environments/production.rb', /config.active_support.deprecation = :notify/ do
  <<-RUBY
config.active_support.deprecation = :notify

  config.action_mailer.default_url_options = { :host => 'yourhost.com' }
  # ActionMailer Config
  # Setup for production - deliveries, no errors raised
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default :charset => "utf-8"
RUBY
  end
  
end


# >--------------------------------[ Devise ]---------------------------------<

@current_recipe = "devise"
@before_configs["devise"].call if @before_configs["devise"]
say_recipe 'Devise'

config = {}
config['devise'] = yes_wizard?("Would you like to use Devise for authentication?") if true && true unless config.key?('devise')
@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/devise.rb

if config['devise']
  if recipes.include? 'rails 3.0'
    # for Rails 3.0, use only gem versions we know that work
    gem 'devise', '1.3.4'
  else
    # for Rails 3.1+, use optimistic versioning for gems
    gem 'devise', '>= 1.4.5'
  end
else
  recipes.delete('devise')
end


if config['devise']
  after_bundler do
    
    say_wizard "Devise recipe running 'after bundler'"
    
    # Run the Devise generator
    generate 'devise:install'

    if recipes.include? 'mongo_mapper'
      gem 'mm-devise'
      gsub_file 'config/initializers/devise.rb', 'devise/orm/', 'devise/orm/mongo_mapper_active_model'
      generate 'mongo_mapper:devise User'
    elsif recipes.include? 'mongoid'
      # Nothing to do (Devise changes its initializer automatically when Mongoid is detected)
      # gsub_file 'config/initializers/devise.rb', 'devise/orm/active_record', 'devise/orm/mongoid'
    end

    # Prevent logging of password_confirmation
    gsub_file 'config/application.rb', /:password/, ':password, :password_confirmation'

    if recipes.include? 'cucumber'
      # Cucumber wants to test GET requests not DELETE requests for destroy_user_session_path
      # (see https://github.com/RailsApps/rails3-devise-rspec-cucumber/issues/3)
      gsub_file 'config/initializers/devise.rb', 'config.sign_out_via = :delete', 'config.sign_out_via = Rails.env.test? ? :get : :delete'
    end
    
  end

  after_everything do

    say_wizard "Devise recipe running 'after everything'"

    if recipes.include? 'rspec'
      say_wizard "Copying RSpec files from the rails3-devise-rspec-cucumber examples"
      begin
        # copy all the RSpec specs files from the rails3-devise-rspec-cucumber example app
        get 'https://raw.github.com/RailsApps/rails3-devise-rspec-cucumber/master/spec/factories.rb', 'spec/factories.rb'
        remove_file 'spec/controllers/home_controller_spec.rb'
        remove_file 'spec/controllers/users_controller_spec.rb'
        get 'https://raw.github.com/RailsApps/rails3-devise-rspec-cucumber/master/spec/controllers/home_controller_spec.rb', 'spec/controllers/home_controller_spec.rb'
        get 'https://raw.github.com/RailsApps/rails3-devise-rspec-cucumber/master/spec/controllers/users_controller_spec.rb', 'spec/controllers/users_controller_spec.rb'
        remove_file 'spec/models/user_spec.rb'
        get 'https://raw.github.com/RailsApps/rails3-devise-rspec-cucumber/master/spec/models/user_spec.rb', 'spec/models/user_spec.rb'
      rescue OpenURI::HTTPError
        say_wizard "Unable to obtain RSpec example files from the repo"
      end
      remove_file 'spec/views/home/index.html.erb_spec.rb'
      remove_file 'spec/views/home/index.html.haml_spec.rb'
      remove_file 'spec/views/users/show.html.erb_spec.rb'
      remove_file 'spec/views/users/show.html.haml_spec.rb'
      remove_file 'spec/helpers/home_helper_spec.rb'
      remove_file 'spec/helpers/users_helper_spec.rb'
    end

  end
end

# >--------------------------------[ CanCan ]--------------------------------<
@current_recipe = "cancan"
@before_configs["cancan"].call if @before_configs["cancan"]
say_recipe 'CanCan'

config = {}
config['cancan'] = yes_wizard?("Would you like to use CanCan for authorization?") if true && true unless config.key?('cancan')
@configs[@current_recipe] = config

if config['cancan']
  gem 'cancan'
else
  recipes.delete('cancan')
end

create_file 'app/models/ability.rb' do 
<<-'Ability'
class Ability
  include CanCan::Ability

  def initialize(user)
    can :manage, :all #uncomment this and set new roles and abilities later
    
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
Ability
end

# >--------------------------------[ RailsAdmin ]--------------------------------<
@current_recipe = "rails_admin"
@before_configs["rails_admin"].call if @before_configs["rails_admin"]
say_recipe 'RailsAdmin'

config = {}
config['rails_admin'] = yes_wizard?("Would you like to use Rails Admin for Backend?") if true && true unless config.key?('rails_admin')
@configs[@current_recipe] = config

if config['rails_admin']
  gem 'rails_admin', :git => 'http://github.com/sferik/rails_admin.git'
  gem 'ckeditor'
  gem 'paperclip'
  gem 'kaminari'
  gem 'fastercsv'
  gem 'truncate_html'
else
  recipes.delete('rails_admin')
end

create_file 'config/initializers/rails_admin.rb' do 
<<-'RailsAdminConfig'
RailsAdmin.config do |config|
  config.authorize_with :cancan
  config.models do
    list do
      fields_of_type :datetime do
        date_format :compact
      end
    end
  end
end
RailsAdminConfig
end
after_bundler do
  say_wizard "Add Rails Admin Asset Files"
  generate "rails_admin:install"
end
inject_into_file 'config/application.rb', :after => "Rails::Application\n" do
<<-'RailsAdminConfig'
    config.assets.enabled = true
RailsAdminConfig
end

inject_into_file 'config/routes.rb', :after => "Application.routes.draw do\n" do
<<-'RailsAdminConfig'
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'
RailsAdminConfig
end



# >--------------------------------[ AddUser ]--------------------------------<

@current_recipe = "add_user"
@before_configs["add_user"].call if @before_configs["add_user"]
say_recipe 'AddUser'


@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/add_user.rb

after_bundler do
  
  say_wizard "AddUser recipe running 'after bundler'"
  
  if recipes.include? 'omniauth'
    generate(:model, "user provider:string uid:string name:string email:string")
    gsub_file 'app/models/user.rb', /end/ do
<<-RUBY
  attr_accessible :provider, :uid, :name, :email
end
RUBY
    end
  end

  if recipes.include? 'devise'
    
    # Generate models and routes for a User
    #generate 'devise user'

    # Add a 'name' attribute to the User model
    if recipes.include? 'mongoid'
      gsub_file 'app/models/user.rb', /end/ do
  <<-RUBY
  field :name
  validates_presence_of :name
  validates_uniqueness_of :name, :email, :case_sensitive => false
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me
end
RUBY
      end
    else
      # for ActiveRecord
      # Devise created a Users database, we'll modify it
      generate 'migration AddNameToUsers name:string'
      # Devise created a Users model, we'll modify it
      gsub_file 'app/models/user.rb', /attr_accessible :email/, 'attr_accessible :name, :email'
      inject_into_file 'app/models/user.rb', :before => 'validates_uniqueness_of' do
        "validates_presence_of :name\n"
      end
      gsub_file 'app/models/user.rb', /validates_uniqueness_of :email/, 'validates_uniqueness_of :name, :email'
    end

    unless recipes.include? 'haml'
      
      # Generate Devise views (unless you are using Haml)
      run 'rails generate devise:views'
      
      # Modify Devise views to add 'name'
      inject_into_file "app/views/devise/registrations/edit.html.erb", :after => "<%= devise_error_messages! %>\n" do
      <<-ERB
<p><%= f.label :name %><br />
<%= f.text_field :name %></p>
ERB
      end

      inject_into_file "app/views/devise/registrations/new.html.erb", :after => "<%= devise_error_messages! %>\n" do
      <<-ERB
<p><%= f.label :name %><br />
<%= f.text_field :name %></p>
ERB
      end

    else

      # copy Haml versions of modified Devise views
      inside 'app/views/devise/registrations' do
        get 'https://raw.github.com/RailsApps/rails3-application-templates/master/files/rails3-mongoid-devise/app/views/devise/registrations/edit.html.haml', 'edit.html.haml'
        get 'https://raw.github.com/RailsApps/rails3-application-templates/master/files/rails3-mongoid-devise/app/views/devise/registrations/new.html.haml', 'new.html.haml'
      end

    end

  end

end


# >-------------------------------[ HomePage ]--------------------------------<

@current_recipe = "home_page"
@before_configs["home_page"].call if @before_configs["home_page"]
say_recipe 'HomePage'


@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/home_page.rb

after_bundler do
  
  say_wizard "HomePage recipe running 'after bundler'"
  
  # remove the default home page
  remove_file 'public/index.html'
  
  # create a home controller and view
  generate(:controller, "home index")

  # set up a simple home page (with placeholder content)
  if recipes.include? 'haml'
    remove_file 'app/views/home/index.html.haml'
    # There is Haml code in this script. Changing the indentation is perilous between HAMLs.
    # We have to use single-quote-style-heredoc to avoid interpolation.
    create_file 'app/views/home/index.html.haml' do 
    <<-'HAML'
%h3 Home
HAML
    end
  else
    remove_file 'app/views/home/index.html.erb'
    create_file 'app/views/home/index.html.erb' do 
    <<-ERB
<h3>Home</h3>
ERB
    end
  end

  # set routes
  gsub_file 'config/routes.rb', /get \"home\/index\"/, 'root :to => "home#index"'

end


# >-----------------------------[ HomePageUsers ]-----------------------------<

@current_recipe = "home_page_users"
@before_configs["home_page_users"].call if @before_configs["home_page_users"]
say_recipe 'HomePageUsers'


@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/home_page_users.rb

after_bundler do

  say_wizard "HomePageUsers recipe running 'after bundler'"

  # Modify the home controller
  gsub_file 'app/controllers/home_controller.rb', /def index/ do
  <<-RUBY
def index
  @users = User.all
RUBY
  end

  # Replace the home page
  if recipes.include? 'haml'
    remove_file 'app/views/home/index.html.haml'
    # There is Haml code in this script. Changing the indentation is perilous between HAMLs.
    # We have to use single-quote-style-heredoc to avoid interpolation.
    create_file 'app/views/home/index.html.haml' do 
    <<-'HAML'
%h3 Home
- @users.each do |user|
  %p User: #{user.name}
HAML
    end
  else
    append_file 'app/views/home/index.html.erb' do <<-ERB
<h3>Home</h3>
<% @users.each do |user| %>
  <p>User: <%= user.name %></p>
<% end %>
ERB
    end
  end

end


# >-------------------------------[ UsersPage ]-------------------------------<

@current_recipe = "users_page"
@before_configs["users_page"].call if @before_configs["users_page"]
say_recipe 'UsersPage'


@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/users_page.rb

after_bundler do

  say_wizard "UsersPage recipe running 'after bundler'"

    #----------------------------------------------------------------------------
    # Create a users controller
    #----------------------------------------------------------------------------
    generate(:controller, "users show")
    gsub_file 'app/controllers/users_controller.rb', /def show/ do
    <<-RUBY
before_filter :authenticate_user!

  def show
    @user = User.find(params[:id])
RUBY
    end

    #----------------------------------------------------------------------------
    # Modify the routes
    #----------------------------------------------------------------------------
    # @devise_for :users@ route must be placed above @resources :users, :only => :show@.
    gsub_file 'config/routes.rb', /get \"users\/show\"/, '#get \"users\/show\"'
    gsub_file 'config/routes.rb', /devise_for :users/ do
    <<-RUBY
devise_for :users
  resources :users, :only => :show
RUBY
    end

    #----------------------------------------------------------------------------
    # Create a users show page
    #----------------------------------------------------------------------------
    if recipes.include? 'haml'
      remove_file 'app/views/users/show.html.haml'
      # There is Haml code in this script. Changing the indentation is perilous between HAMLs.
      # We have to use single-quote-style-heredoc to avoid interpolation.
      create_file 'app/views/users/show.html.haml' do <<-'HAML'
%p
  User: #{@user.name}
%p
  Email: #{@user.email if @user.email}
HAML
      end
    else
      append_file 'app/views/users/show.html.erb' do <<-ERB
<p>User: <%= @user.name %></p>
<p>Email: <%= @user.email if @user.email %></p>
ERB
      end
    end

    #----------------------------------------------------------------------------
    # Create a home page containing links to user show pages
    # (clobbers code from the home_page_users recipe)
    #----------------------------------------------------------------------------
    # set up the controller
    remove_file 'app/controllers/home_controller.rb'
    create_file 'app/controllers/home_controller.rb' do
    <<-RUBY
class HomeController < ApplicationController
  def index
    @users = User.all
  end
end
RUBY
    end

    # modify the home page
    if recipes.include? 'haml'
      remove_file 'app/views/home/index.html.haml'
      # There is Haml code in this script. Changing the indentation is perilous between HAMLs.
      # We have to use single-quote-style-heredoc to avoid interpolation.
      create_file 'app/views/home/index.html.haml' do
      <<-'HAML'
%h3 Home
- @users.each do |user|
  %p User: #{link_to user.name, user}
HAML
      end
    else
      remove_file 'app/views/home/index.html.erb'
      create_file 'app/views/home/index.html.erb' do <<-ERB
<h3>Home</h3>
<% @users.each do |user| %>
  <p>User: <%=link_to user.name, user %></p>
<% end %>
ERB
      end
    end

end


# >-------------------------------[ CssSetup ]--------------------------------<

@current_recipe = "css_setup"
@before_configs["css_setup"].call if @before_configs["css_setup"]
say_recipe 'CssSetup'


@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/css_setup.rb

after_bundler do

  say_wizard "CssSetup recipe running 'after bundler'"

  # Add a stylesheet with styles for a horizontal menu and flash messages
  css = <<-CSS

ul.hmenu {
  list-style: none;
  margin: 0 0 2em;
  padding: 0;
}
ul.hmenu li {
  display: inline;
}
#flash_notice, #flash_alert {
  padding: 5px 8px;
  margin: 10px 0;
}
#flash_notice {
  background-color: #CFC;
  border: solid 1px #6C6;
}
#flash_alert {
  background-color: #FCC;
  border: solid 1px #C66;
}

CSS

  # Add a stylesheet for use with HTML5 Boilerplate
  css_boilerplate = <<-CSS

header nav ul {
  list-style: none;
  margin: 0 0 2em;
  padding: 0;
}
header nav ul li {
  display: inline;
}
#flash_notice, #flash_alert {
  padding: 5px 8px;
  margin: 10px 0;
}
#flash_notice {
  background-color: #CFC;
  border: solid 1px #6C6;
}
#flash_alert {
  background-color: #FCC;
  border: solid 1px #C66;
}

CSS

  if recipes.include? 'rails 3.0'
    create_file 'public/stylesheets/application.css', css
  else
    if recipes.include? 'html5'
      append_file 'app/assets/stylesheets/application.css', css_boilerplate
    else
      append_file 'app/assets/stylesheets/application.css', css
    end
  end

end


# >---------------------------[ ApplicationLayout ]---------------------------<

@current_recipe = "application_layout"
@before_configs["application_layout"].call if @before_configs["application_layout"]
say_recipe 'ApplicationLayout'


@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/application_layout.rb

after_bundler do

  say_wizard "ApplicationLayout recipe running 'after bundler'"

  # Set up the default application layout
  if recipes.include? 'haml'
    remove_file 'app/views/layouts/application.html.erb'
    remove_file 'app/views/layouts/application.html.haml'
    # There is Haml code in this script. Changing the indentation is perilous between HAMLs.
    create_file 'app/views/layouts/application.html.haml' do <<-HAML
!!! 5
%html
  %head
    %title #{app_name}
    = stylesheet_link_tag :application
    = javascript_include_tag :application
    = csrf_meta_tags
  %body
    - flash.each do |name, msg|
      = content_tag :div, msg, :id => "flash_\#{name}" if msg.is_a?(String)
    = yield
HAML
    end
    if recipes.include? 'rails 3.0'
      gsub_file 'app/views/layouts/application.html.haml', /stylesheet_link_tag :application/, 'stylesheet_link_tag :all'
      gsub_file 'app/views/layouts/application.html.haml', /javascript_include_tag :application/, 'javascript_include_tag :defaults'
      gsub_file 'app/views/layouts/application.html.haml', /csrf_meta_tags/, 'csrf_meta_tag'
    end
  else
    unless recipes.include? 'html5'
      inject_into_file 'app/views/layouts/application.html.erb', :after => "<body>\n" do
    <<-ERB
  <%- flash.each do |name, msg| -%>
    <%= content_tag :div, msg, :id => "flash_\#{name}" if msg.is_a?(String) %>
  <%- end -%>
ERB
      end
    end
  end

end


# >---------------------------------[ html5 ]---------------------------------<

@current_recipe = "html5"
@before_configs["html5"].call if @before_configs["html5"]
say_recipe 'html5'

config = {}
config['html5'] = yes_wizard?("Would you like to install HTML5 Boilerplate?") if true && true unless config.key?('html5')
config['css_option'] = multiple_choice("If you've chosen HTML5 Boilerplate, how do you like your CSS?", [["Do nothing", "nothing"], ["Normalize CSS and add Skeleton styling", "skeleton"], ["Normalize CSS for consistent styling across browsers", "normalize"], ["Completely reset all CSS to eliminate styling", "reset"]]) if true && true unless config.key?('css_option')
@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/html5.rb

if config['html5']
  if recipes.include? 'rails 3.1'
    gem 'frontend-helpers'
    after_bundler do
      say_wizard "HTML5 Boilerplate recipe running 'after bundler'"
      # Download HTML5 Boilerplate JavaScripts
      get "https://raw.github.com/paulirish/html5-boilerplate/master/js/libs/modernizr-2.0.6.min.js", "app/assets/javascripts/modernizr.js"
      # Download stylesheet to normalize or reset CSS
      case config['css_option']
        when 'skeleton'
          get "https://raw.github.com/necolas/normalize.css/master/normalize.css", "app/assets/stylesheets/normalize.css.scss"
          get "https://raw.github.com/dhgamache/Skeleton/master/stylesheets/base.css", "app/assets/stylesheets/base.css.scss"
          get "https://raw.github.com/dhgamache/Skeleton/master/stylesheets/layout.css", "app/assets/stylesheets/layout.css.scss"
          get "https://raw.github.com/dhgamache/Skeleton/master/stylesheets/skeleton.css", "app/assets/stylesheets/skeleton.css.scss"
          get "https://raw.github.com/dhgamache/Skeleton/master/javascripts/tabs.js", "app/assets/javascripts/tabs.js"
        when 'normalize'
          get "https://raw.github.com/necolas/normalize.css/master/normalize.css", "app/assets/stylesheets/normalize.css.scss"
        when 'reset'
          get "https://raw.github.com/paulirish/html5-boilerplate/master/css/style.css", "app/assets/stylesheets/reset.css.scss"
      end
      # Download HTML5 Boilerplate Site Root Assets
      get "https://raw.github.com/paulirish/html5-boilerplate/master/apple-touch-icon-114x114-precomposed.png", "public/apple-touch-icon-114x114-precomposed.png"
      get "https://raw.github.com/paulirish/html5-boilerplate/master/apple-touch-icon-57x57-precomposed.png", "public/apple-touch-icon-57x57-precomposed.png"
      get "https://raw.github.com/paulirish/html5-boilerplate/master/apple-touch-icon-72x72-precomposed.png", "public/apple-touch-icon-72x72-precomposed.png"
      get "https://raw.github.com/paulirish/html5-boilerplate/master/apple-touch-icon-precomposed.png", "public/apple-touch-icon-precomposed.png"
      get "https://raw.github.com/paulirish/html5-boilerplate/master/apple-touch-icon.png", "public/apple-touch-icon.png"
      get "https://raw.github.com/paulirish/html5-boilerplate/master/crossdomain.xml", "public/crossdomain.xml"
      get "https://raw.github.com/paulirish/html5-boilerplate/master/humans.txt", "public/humans.txt"
      # Set up the default application layout
      if recipes.include? 'haml'
        # create some Haml helpers
        # We have to use single-quote-style-heredoc to avoid interpolation.
        inject_into_file 'app/controllers/application_controller.rb', :after => "protect_from_forgery\n" do <<-'RUBY'
  include FrontendHelpers::Html5Helper
RUBY
        end
        # Haml version of default application layout
        remove_file 'app/views/layouts/application.html.erb'
        remove_file 'app/views/layouts/application.html.haml'
        # There is Haml code in this script. Changing the indentation is perilous between HAMLs.
        create_file 'app/views/layouts/application.html.haml' do <<-HAML
- html_tag class: 'no-js' do
  %head
    %title #{app_name}
    %meta{:charset => "utf-8"}
    %meta{"http-equiv" => "X-UA-Compatible", :content => "IE=edge,chrome=1"}
    %meta{:name => "viewport", :content => "width=device-width, initial-scale=1, maximum-scale=1"}
    = stylesheet_link_tag :application
    = javascript_include_tag :application
    = csrf_meta_tags
  %body{:class => params[:controller]}
    #container.container
      %header
        - flash.each do |name, msg|
          = content_tag :div, msg, :id => "flash_\#{name}" if msg.is_a?(String)
      #main{:role => "main"}
        = yield
      %footer
HAML
        end
      else
        # ERB version of default application layout
        remove_file 'app/views/layouts/application.html.erb'
        remove_file 'app/views/layouts/application.html.haml'
        create_file 'app/views/layouts/application.html.erb' do <<-ERB
<!doctype html>
<!--[if lt IE 7]> <html class="no-js ie6 oldie" lang="en"> <![endif]-->
<!--[if IE 7]>    <html class="no-js ie7 oldie" lang="en"> <![endif]-->
<!--[if IE 8]>    <html class="no-js ie8 oldie" lang="en"> <![endif]-->
<!--[if gt IE 8]><!--> <html class="no-js" lang="en"> <!--<![endif]-->
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>#{app_name}</title>
  <meta name="description" content="">
  <meta name="author" content="">
  <%= stylesheet_link_tag    "application" %>
  <%= javascript_include_tag "application" %>
  <%= csrf_meta_tags %>
</head>
<body class="<%= params[:controller] %>">
  <div id="container" class="container">
    <header>
    </header>
    <div id="main" role="main">
      <%= yield %>
    </div>
    <footer>
    </footer>
  </div> <!--! end of #container -->
</body>
</html>
ERB
        end
        inject_into_file 'app/views/layouts/application.html.erb', :after => "<header>\n" do
  <<-ERB
      <%- flash.each do |name, msg| -%>
        <%= content_tag :div, msg, :id => "flash_\#{name}" if msg.is_a?(String) %>
      <%- end -%>
ERB
        end
      end
    end
  elsif recipes.include? 'rails 3.0'
    say_wizard "Not supported for Rails version #{Rails::VERSION::STRING}. HTML5 Boilerplate recipe skipped."
  else
    say_wizard "Don't know what to do for Rails version #{Rails::VERSION::STRING}. HTML5 Boilerplate recipe skipped."
  end
else
  say_wizard "HTML5 Boilerplate recipe skipped. No CSS styles added."
  recipes.delete('html5')
end


# >------------------------------[ Navigation ]-------------------------------<

@current_recipe = "navigation"
@before_configs["navigation"].call if @before_configs["navigation"]
say_recipe 'Navigation'


@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/navigation.rb

after_bundler do

  say_wizard "Navigation recipe running 'after bundler'"
  
    if recipes.include? 'devise'
      # Create navigation links for Devise
      if recipes.include? 'haml'
        # There is Haml code in this script. Changing the indentation is perilous between HAMLs.
        # We have to use single-quote-style-heredoc to avoid interpolation.
        create_file "app/views/shared/_navigation.html.haml" do <<-'HAML'
- if user_signed_in?
  %li
    = link_to('Logout', destroy_user_session_path, :method=>'delete')
- else
  %li
    = link_to('Login', new_user_session_path)
- if user_signed_in?
  %li
    = link_to('Edit account', edit_user_registration_path)
- else
  %li
    = link_to('Sign up', new_user_registration_path)
HAML
        end
      else
        create_file "app/views/shared/_navigation.html.erb" do <<-ERB
<% if user_signed_in? %>
  <li>
  <%= link_to('Logout', destroy_user_session_path, :method=>'delete') %>        
  </li>
<% else %>
  <li>
  <%= link_to('Login', new_user_session_path)  %>  
  </li>
<% end %>
<% if user_signed_in? %>
  <li>
  <%= link_to('Edit account', edit_user_registration_path) %>
  </li>
<% else %>
  <li>
  <%= link_to('Sign up', new_user_registration_path)  %>
  </li>
<% end %>
ERB
        end
      end

    else
      # Create navigation links
      if recipes.include? 'haml'
        # There is Haml code in this script. Changing the indentation is perilous between HAMLs.
        # We have to use single-quote-style-heredoc to avoid interpolation.
        create_file "app/views/shared/_navigation.html.haml" do <<-'HAML'
- if user_signed_in?
  %li
    Logged in as #{current_user.name}
  %li
    = link_to('Logout', signout_path)
- else
  %li
    = link_to('Login', signin_path)
HAML
        end
      else
        create_file "app/views/shared/_navigation.html.erb" do <<-ERB
<% if user_signed_in? %>
  <li>
  Logged in as <%= current_user.name %>
  </li>
  <li>
  <%= link_to('Logout', signout_path) %>        
  </li>
<% else %>
  <li>
  <%= link_to('Login', signin_path)  %>  
  </li>
<% end %>
ERB
        end
      end
    end

    # Add navigation links to the default application layout
    if recipes.include? 'html5'
      if recipes.include? 'haml'
        # There is Haml code in this script. Changing the indentation is perilous between HAMLs.
        inject_into_file 'app/views/layouts/application.html.haml', :after => "%header\n" do <<-HAML
        %nav
          %ul.hmenu
            = render 'shared/navigation'
HAML
        end
      else
        inject_into_file 'app/views/layouts/application.html.erb', :after => "<header>\n" do <<-ERB
        <nav>
          <ul class="hmenu">
            <%= render 'shared/navigation' %>
          </ul>
        </nav>
ERB
        end
      end
    else
      if recipes.include? 'haml'
        # There is Haml code in this script. Changing the indentation is perilous between HAMLs.
        inject_into_file 'app/views/layouts/application.html.haml', :after => "%body\n" do <<-HAML
    %ul.hmenu
      = render 'shared/navigation'
HAML
        end
      else
        inject_into_file 'app/views/layouts/application.html.erb', :after => "<body>\n" do
  <<-ERB
  <ul class="hmenu">
    <%= render 'shared/navigation' %>
  </ul>
ERB
        end
      end
    end

end


# >--------------------------------[ Cleanup ]--------------------------------<

@current_recipe = "cleanup"
@before_configs["cleanup"].call if @before_configs["cleanup"]
say_recipe 'Cleanup'


@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/cleanup.rb

after_bundler do

  say_wizard "Cleanup recipe running 'after bundler'"

  # remove unnecessary files
  %w{
    README
    doc/README_FOR_APP
    public/index.html
  }.each { |file| remove_file file }
  
  if recipes.include? 'rails 3.0'
    %w{
      public/images/rails.png
    }.each { |file| remove_file file }
  else
    %w{
      app/assets/images/rails.png
    }.each { |file| remove_file file }
  end
  
  # add placeholder READMEs
  get "https://raw.github.com/RailsApps/rails3-application-templates/master/files/sample_readme.txt", "README"
  get "https://raw.github.com/RailsApps/rails3-application-templates/master/files/sample_readme.textile", "README.textile"
  gsub_file "README", /App_Name/, "#{app_name.humanize.titleize}"
  gsub_file "README.textile", /App_Name/, "#{app_name.humanize.titleize}"

  # remove commented lines from Gemfile
  # thanks to https://github.com/perfectline/template-bucket/blob/master/cleanup.rb
  gsub_file "Gemfile", /#.*\n/, "\n"
  gsub_file "Gemfile", /\n+/, "\n"

end


# >------------------------------[ BanSpiders ]-------------------------------<

@current_recipe = "ban_spiders"
@before_configs["ban_spiders"].call if @before_configs["ban_spiders"]
say_recipe 'BanSpiders'

config = {}
config['ban_spiders'] = yes_wizard?("Would you like to set a robots.txt file to ban spiders?") if true && true unless config.key?('ban_spiders')
@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/ban_spiders.rb

if config['ban_spiders']
  say_wizard "BanSpiders recipe running 'after bundler'"
  after_bundler do
    # ban spiders from your site by changing robots.txt
    gsub_file 'public/robots.txt', /# User-Agent/, 'User-Agent'
    gsub_file 'public/robots.txt', /# Disallow/, 'Disallow'
  end
else
  recipes.delete('ban_spiders')
end

# >--------------------------------[ Mailer ]---------------------------------<

@current_recipe = "mailer"
@before_configs["mailer"].call if @before_configs["mailer"]
say_recipe 'Mailer'

config = {}
config['mailer'] = yes_wizard?("Would you like to include Mailer?") if true && true unless config.key?('mailer')
@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/extras.rb

if config['mailer']
  after_bundler do
    say_wizard "Adding Mailer options"
    generate "mailer PostOffice"
  end
else
  recipes.delete('mailer')
end


# >--------------------------------[ Sitemap Generator ]---------------------------------<

@current_recipe = "sitemap"
@before_configs["sitemap"].call if @before_configs["sitemap"]
say_recipe 'Sitemap Generator'

config = {}
config['sitemap'] = yes_wizard?("Would you like to include Sitemap Generator?") if true && true unless config.key?('sitemap')
@configs[@current_recipe] = config

if config['sitemap']
  gem 'sitemap_generator'
else
  recipes.delete('sitemap')
end

after_bundler do
  say_wizard "Add Sitemap to Robots.txt"
  append_file 'public/robots.txt' do
<<-'RailsAdminConfig'
Sitemap: http://www.example.com/sitemap_index.xml.gz
RailsAdminConfig
  end
  
  say_wizard "Generate Configuration Model"
  generate(:model, "configuration name:string description:string")
  remove_file 'app/models/configuration.rb'
  create_file 'app/models/configuration.rb' do
<<-'RailsAdminConfig'
class Configuration < ActiveRecord::Base
  after_save :restart
  
  def restart
    f = File.new("#{Rails.root}/config/sitemap.rb", "w+") 
    f.truncate(0)
    f.write("SitemapGenerator::Sitemap.default_host = Configuration.find_by_name('host').description if Configuration.find_by_name('host')\r\n")
    f.write("SitemapGenerator::Sitemap.yahoo_app_id = Configuration.find_by_name('yahoo_app_id').description if Configuration.find_by_name('yahoo_app_id')\r\n")
    f.write("SitemapGenerator::Sitemap.create do\r\n")
    Configuration.where("name = 'for_sitemap'").each do |c|
      f.write("  add #{c.description.downcase}s_path\r\n")
      f.write("  #{c.description.classify}.find_each do |obj|\r\n")
      f.write("    add #{c.description.downcase}_path(obj), :lastmod => obj.updated_at\r\n")
      f.write("  end\r\n")
    end
    f.write("end\r\n")
    f.close
    
    if Configuration.find_by_name('restart').description.downcase == "yes"
      system("touch #{Rails.root}/tmp/restart.txt")
      config = Configuration.find_by_name('restart')
      config.description = "no"
      config.save 
    end if Configuration.find_by_name('restart')
    
    if Configuration.find_by_name('deploy_sitemap').description.downcase == "yes"
      system("rake sitemap:refresh RAILS_ENV=#{Rails.env}")
      config = Configuration.find_by_name('deploy_sitemap')
      config.description = "no"
      config.save
    end if Configuration.find_by_name('deploy_sitemap')
  end
end
RailsAdminConfig
  end
end



# >--------------------------------[ Extras ]---------------------------------<

@current_recipe = "extras"
@before_configs["extras"].call if @before_configs["extras"]
say_recipe 'Extras'

config = {}
config['footnotes'] = yes_wizard?("Would you like to use 'rails-footnotes' during development?") if true && true unless config.key?('footnotes')
@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/extras.rb

if config['footnotes']
  say_wizard "Extras recipe running 'after bundler'"
  gem 'rails-footnotes', '>= 3.7', :group => :development
else
  recipes.delete('footnotes')
end


# >----------------------------------[ Capistrano ]----------------------------------<

@current_recipe = "capistrano"
@before_configs["capistrano"].call if @before_configs["capistrano"]
say_recipe 'Capistrano'

config = {}
@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/extras.rb

say_wizard "Include capistrano script"
gem 'capistrano'
after_bundler do
  #run 'capify'
  
  remove_file 'config/deploy.rb'
  create_file 'Capfile' do
<<-'Capfile'
load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

load 'config/deploy' # remove this line to skip loading any of the default tasks
Capfile
  end
  
  create_file 'config/deploy.rb' do 
<<-'ERB'
set :scm,           :mercurial # :git
set :user,          ''
set :password,      ''
set :deploy_to,     ''
set :application,   ''
set :repository,    ''
set :use_sudo,      false
server "", :app, :web, :db, :primary => true

after "deploy:symlink" do
  run "cd #{current_path} && bundle"
end

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
  
  desc "Run the migrate rake task."
  task :migrate do
    run "cd #{current_path} && rake RAILS_ENV=production  db:migrate"
  end

  desc "DB reset, and seed"
  task :reset_db do
    run "cd #{current_path} && rake db:migrate VERSION=0 && rake db:migrate && rake db:seed"
  end
end

namespace :remote do
  desc "tail production log files"
  task :logs do
    run "tail -f #{current_path}/log/production.log" do |channel, stream, data|
      puts  # for an extra line break before the host name
      puts "#{channel[:host]}: #{data}" 
      break if stream == :err    
    end
  end
  
  desc "remote console"
  task :console do
    input = ''
    run "cd #{current_path} && rails c #{ENV['RAILS_ENV']}" do |channel, stream, data|
      next if data.chomp == input.chomp || data.chomp == ''
      print data
      channel.send_data(input = $stdin.gets) if data =~ /^(>|\?)>/
    end
  end
end

after 'deploy', 'deploy:migrate'
after 'deploy', 'deploy:cleanup'
ERB
  end
end

recipes.delete('capistrano')


# >-----------------------------[ SeedDatabase ]------------------------------<

@current_recipe = "seed_database"
@before_configs["seed_database"].call if @before_configs["seed_database"]
say_recipe 'SeedDatabase'


@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/seed_database.rb


after_bundler do

  say_wizard "SeedDatabase recipe running 'after bundler'"

  unless recipes.include? 'mongoid'
    run 'bundle exec rake db:migrate'
  end

  if recipes.include? 'mongoid'
    append_file 'db/seeds.rb' do <<-FILE
puts 'EMPTY THE MONGODB DATABASE'
Mongoid.master.collections.reject { |c| c.name =~ /^system/}.each(&:drop)
FILE
    end
  end

  if recipes.include? 'devise'
    # create a default user
    append_file 'db/seeds.rb' do <<-FILE
puts 'SETTING UP DEFAULT USER LOGIN'
user = User.create! :name => 'First User', :email => 'user@test.com', :password => 'please', :password_confirmation => 'please'
puts 'New user created: ' << user.name
FILE
    end
  end
  
  append_file 'db/seeds.rb' do 
    say_wizard 'Add Default Config settings'
<<-'FILE'
Configuration.create! :name => 'restart', :description => 'no'
Configuration.create! :name => 'for_sitemap', :description => 'no'
Configuration.create! :name => 'host', :description => 'http://www.example.com'
Configuration.create! :name => 'deploy_sitemap', :description => 'no'
Configuration.create! :name => 'yahoo_app_id'
FILE
  end

  run 'bundle exec rake db:seed'

end




# >----------------------------------[ Git ]----------------------------------<

@current_recipe = "git"
@before_configs["git"].call if @before_configs["git"]
say_recipe 'Git'


@configs[@current_recipe] = config

# Application template recipe for the rails_apps_composer. Check for a newer version here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/git.rb

after_everything do
  
  say_wizard "Git recipe running 'after everything'"
  
  # Git should ignore some files
  remove_file '.gitignore'
  get "https://raw.github.com/RailsApps/rails3-application-templates/master/files/gitignore.txt", ".gitignore"

  if recipes.include? 'omniauth'
    append_file '.gitignore' do 
<<-TXT

# keep OmniAuth service provider secrets out of the Git repo
config/initializers/omniauth.rb
TXT
    end
  end

  # Initialize new Git repo
  git :init
  git :add => '.'
  git :commit => "-aqm 'new Rails app generated by Rails Apps Composer gem'"
  # Create a git branch
  git :checkout => ' -b working_branch'
  git :add => '.'
  git :commit => "-m 'Initial commit of working_branch'"
  git :checkout => 'master'
end





@current_recipe = nil

# >-----------------------------[ Run Bundler ]-------------------------------<

say_wizard "Running 'bundle install'. This will take a while."
run 'bundle install'
say_wizard "Running 'after bundler' callbacks."
require 'bundler/setup'
@after_blocks.each{|b| config = @configs[b[0]] || {}; @current_recipe = b[0]; b[1].call}

@current_recipe = nil
say_wizard "Running 'after everything' callbacks."
@after_everything_blocks.each{|b| config = @configs[b[0]] || {}; @current_recipe = b[0]; b[1].call}

@current_recipe = nil
say_wizard "Finished running the rails_apps_composer app template."
say_wizard "Your new Rails app is ready."