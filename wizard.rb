# >---------------------------------------------------------------------------<
#
#            _____       _ _   __          ___                  _ 
#           |  __ \     (_) |  \ \        / (_)                | |
#           | |__) |__ _ _| |___\ \  /\  / / _ ______ _ _ __ __| |
#           |  _  // _` | | / __|\ \/  \/ / | |_  / _` | '__/ _` |
#           | | \ \ (_| | | \__ \ \  /\  /  | |/ / (_| | | | (_| |
#           |_|  \_\__,_|_|_|___/  \/  \/   |_/___\__,_|_|  \__,_|
#
#   This template was generated by RailsWizard, the amazing and awesome Rails
#     application template builder. Get started at http://railswizard.org
#
# >---------------------------------------------------------------------------<

# >----------------------------[ Initial Setup ]------------------------------<

initializer 'generators.rb', <<-RUBY
Rails.application.config.generators do |g|
end
RUBY
#"jquery",
@recipes = ["activerecord", "cucumber", "env_yaml", "haml", "mailer", "rails_admin", "sass", "html5", "authorization", "sitemap_generator", "products" "cleanup"] 

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



# >-----------------------------[ ActiveRecord ]------------------------------<

@current_recipe = "activerecord"
@before_configs["activerecord"].call if @before_configs["activerecord"]
say_recipe 'ActiveRecord'

config = {}
config['database'] = multiple_choice("Which database are you using?", [["MySQL", "mysql"], ["Oracle", "oracle"], ["PostgreSQL", "postgresql"], ["SQLite", "sqlite3"], ["Frontbase", "frontbase"], ["IBM DB", "ibm_db"]]) if true && true unless config.key?('database')
config['auto_create'] = yes_wizard?("Automatically create database with default configuration?") if true && true unless config.key?('auto_create')
@configs[@current_recipe] = config

if config['database']
  say_wizard "Configuring '#{config['database']}' database settings..."
  old_gem = gem_for_database
  @options = @options.dup.merge(:database => config['database'])
  #gsub_file 'Gemfile', "gem '#{old_gem}'", "gem '#{gem_for_database}'"
  template "config/databases/#{@options[:database]}.yml", "config/database.yml.new"
  #run 'mv config/database.yml.new config/database.yml'
end

after_bundler do
  rake "db:create:all" if config['auto_create']
end


# >-------------------------------[ Cucumber ]--------------------------------<

@current_recipe = "cucumber"
@before_configs["cucumber"].call if @before_configs["cucumber"]
say_recipe 'Cucumber'

config['cucumber'] = yes_wizard?("Use Cucumber Test framework?") if true && true unless config.key?('cucumber')
@configs[@current_recipe] = config

if config['cucumber']
  gem 'cucumber-rails', :group => [:development, :test]
  gem 'capybara', :group => [:development, :test]

  after_bundler do
    generate "cucumber:install --capybara#{' --rspec' if recipes.include?('rspec')}#{' -D' unless recipes.include?('activerecord')}"
  end
end

# >--------------------------------[ EnvYAML ]--------------------------------<

@current_recipe = "env_yaml"
@before_configs["env_yaml"].call if @before_configs["env_yaml"]
say_recipe 'EnvYAML'


@configs[@current_recipe] = config

say_wizard "Generating config/env.yaml..."

append_file "config/application.rb", <<-RUBY

require 'env_yaml'
RUBY

create_file "lib/env_yaml.rb", <<-RUBY
require 'yaml'
begin
  env_yaml = YAML.load_file(File.dirname(__FILE__) + '/../config/env.yml')
  if env_hash = env_yaml[ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development']
    env_hash.each_pair do |k,v|
      ENV[k] = v.to_s
    end
  end
rescue StandardError => e
end

RUBY

create_file "config/env.yml", <<-YAML
defaults: &defaults
  ENV_YAML: true

development:
  <<: *defaults

test:
  <<: *defaults

production:
  <<: *defaults
YAML

def env(k,v,rack_env='development')
  inject_into_file "config/env.yml", :after => "#{rack_env}:\n  <<: *defaults" do
    <<-YAML
#{k}: #{v.inspect}    
YAML
  end
end


# >---------------------------------[ HAML ]----------------------------------<

@current_recipe = "haml"
@before_configs["haml"].call if @before_configs["haml"]
say_recipe 'HAML with Formtastic'


@configs[@current_recipe] = config

gem 'haml', '>= 3.0.0'
gem 'haml-rails'
gem 'formtastic'


# >--------------------------------[ jQuery ]---------------------------------<

@current_recipe = "jquery"
@before_configs["jquery"].call if @before_configs["jquery"]
say_recipe 'jQuery'

config = {}
#config['ui'] = yes_wizard?("Install jQuery UI?") if true && true unless config.key?('ui')
@configs[@current_recipe] = config

gem 'jquery-rails'

#after_bundler do
  #ui = config['ui'] ? ' --ui' : ''
#  generate "jquery:install#{ui}"
#end

# >------------------------------[ RailsAdmin ]-------------------------------<

@current_recipe = "rails_admin"
@before_configs["rails_admin"].call if @before_configs["rails_admin"]
say_recipe 'RailsAdmin with CkEditor'

gem 'devise'
gem 'rails_admin', :git => 'git://github.com/sferik/rails_admin.git'
gem "ckeditor"
gem "paperclip"
gem 'kaminari'

after_bundler do
  generate 'rails_admin:install'
  generate 'ckeditor:install'
  generate 'ckeditor:models --orm=active_record --backend=paperclip'
  
  #hide ckeditor models in RailsAdmin CMS
  gsub_file 'config/initializers/rails_admin.rb', /config.current_user_method { current_user } #auto-generated/ do
    "# use CanCan for authorization
    config.authorize_with :cancan
    config.current_user_method { current_user } #auto-generated
    # hide Ckeditor Assets from RailsAdmin CMS
    config.excluded_models = ['Ckeditor::Picture', 'Ckeditor::AttachmentFile', 'Ckeditor::Asset']
    # default field formats
    config.models do
      list do
        fields_of_type :datetime do
          date_format :short
        end
      end
      create do
        fields_of_type :text do
          ckeditor true
        end
      end
      edit do
        fields_of_type :text do
          ckeditor true
        end
      end
    end
    "
  end
end


# >---------------------------------[ SASS ]----------------------------------<

@current_recipe = "sass"
@before_configs["sass"].call if @before_configs["sass"]
say_recipe 'SASS'


@configs[@current_recipe] = config

unless recipes.include? 'haml'
  gem 'haml', '>= 3.0.0'
end

# >---------------------------------[ html5 ]---------------------------------<

@current_recipe = "html5"
@before_configs["html5"].call if @before_configs["html5"]
say_recipe 'HTML5 Boiler Plate'

@configs[@current_recipe] = config

# HTML5 Boiler Plate for Rails
# Written by: Russ Frisch
# http://github.com/russfrisch/h5bp-rails

# Download HTML5 Boilerplate plugins.js (converted to CoffeeScript)
get "https://github.com/russfrisch/h5bp-rails/raw/master/assets/plugins.js.coffee", "app/assets/javascripts/plugins.js.coffee"

# Download and merge HTML5 Boilerplate stylesheet with application.css
inside('app/assets/stylesheets/') do
  FileUtils.rm_rf 'application.css'
  FileUtils.touch 'application.css'
end
prepend_to_file 'app/assets/stylesheets/application.css' do
  " /*
 * This is a manifest file that'll automatically include all the stylesheets available in this directory
 * and any sub-directories. You're free to add application-wide styles to this file and they'll appear at
 * the top of the compiled file, but it's generally better to create a new file per style scope.
 *= require application-pre
 *= require_self
 *= require application-post
*/

"
end
get "https://github.com/paulirish/html5-boilerplate/raw/master/css/style.css", "app/assets/stylesheets/application-pre.css"
get "https://github.com/paulirish/html5-boilerplate/raw/master/css/style.css", "app/assets/stylesheets/application-post.css"
gsub_file 'app/assets/stylesheets/application-pre.css', /\/\* ==\|== media queries.* /m, ''
gsub_file 'app/assets/stylesheets/application-post.css', /\A.*?(==\|== primary styles).*?(\*\/){1}/m, ''
gsub_file 'app/assets/stylesheets/application-pre.css', /==\|==/, '==|==.'
gsub_file 'app/assets/stylesheets/application-post.css', /==\|==/, '==|==.'

# Download HTML5 Boilerplate site root assets
get "https://github.com/russfrisch/html5-boilerplate/raw/master/apple-touch-icon-114x114-precomposed.png", "public/apple-touch-icon-114x114-precomposed.png"
get "https://github.com/russfrisch/html5-boilerplate/raw/master/apple-touch-icon-57x57-precomposed.png", "public/apple-touch-icon-57x57-precomposed.png"
get "https://github.com/russfrisch/html5-boilerplate/raw/master/apple-touch-icon-72x72-precomposed.png", "public/apple-touch-icon-72x72-precomposed.png"
get "https://github.com/russfrisch/html5-boilerplate/raw/master/apple-touch-icon-precomposed.png", "public/apple-touch-icon-precomposed.png"
get "https://github.com/russfrisch/html5-boilerplate/raw/master/apple-touch-icon.png", "public/apple-touch-icon.png"
get "https://github.com/russfrisch/html5-boilerplate/raw/master/crossdomain.xml", "public/crossdomain.xml"
get "https://github.com/russfrisch/html5-boilerplate/raw/master/humans.txt", "public/humans.txt"
get "https://github.com/russfrisch/html5-boilerplate/raw/master/.htaccess", "public/.htaccess"

# Update application.html.erb with HTML5 Boilerplate index.html content
inside('app/views/layouts') do
  FileUtils.rm_rf 'application.html.erb'
end
get "https://github.com/russfrisch/html5-boilerplate/raw/master/index.html", "app/views/layouts/application.html.erb"
gsub_file 'app/views/layouts/application.html.erb', /<link rel="stylesheet" href="css\/style.css">/ do
  "<%= stylesheet_link_tag \"application\" %>"
end
gsub_file 'app/views/layouts/application.html.erb', /<script.*<\/head>/mi do
   "<%= javascript_include_tag \"modernizr\" %>
</head>"
end
gsub_file 'app/views/layouts/application.html.erb', /<meta charset="utf-8">/ do
  "<meta charset=\"utf-8\">
  <%= csrf_meta_tag %>"
end
gsub_file 'app/views/layouts/application.html.erb', /<div id="container">[\s\S]*<\/div>/, '<%= yield %>'
gsub_file 'app/views/layouts/application.html.erb', /<!-- JavaScript[\s\S]*!-- end scripts-->/, '<%= javascript_include_tag "application" %>'

# Add Modernizr-Rails dependency to get Modernizr.js support,
# optional blueprint-rails, coffeebeans, and Heroku dependencies.
gsub_file 'Gemfile', /gem 'jquery-rails'/ do
  "# JavasScript libs
gem 'jquery-rails'
gem 'modernizr-rails'

# Stylesheet libs
# gem 'blueprint-rails'

# Ajax request CoffeeScript support
# gem 'coffeebeans'

# Heroku deployment requirements
# group :production do
#   gem 'therubyracer-heroku'
#   gem 'pg'
# end
"
end

# >-----------------------------[ Authorization ]-------------------------------<
@current_recipe = "authorization"
@before_configs["authorization"].call if @before_configs["authorization"]
say_recipe 'Authorization with CanCan'

@configs[@current_recipe] = config

gem 'cancan'

after_bundler do
  generate 'cancan:ability'
  #load ability.rb to allow initial management
  gsub_file 'app/models/ability.rb', /def initialize\(user\)/ do
    "# let RailsAdmin allow initial user sign-up
    def initialize(user)
      can :manage, :all
    "
  end
end

# >--------------------------------[ Mailer ]---------------------------------<

@current_recipe = "mailer"
@before_configs["mailer"].call if @before_configs["mailer"]
say_recipe 'Mailer'

config = {}
config['mailer'] = yes_wizard?("Would you like to include Mailer?") if true && true unless config.key?('mailer')
@configs[@current_recipe] = config

if config['mailer']
  after_bundler do
    say_wizard "Adding Mailer options"
    generate "mailer PostOffice"
  end
else
  recipes.delete('mailer')
end


# >--------------------------------[ Products ]---------------------------------<

@current_recipe = "products"
@before_configs["products"].call if @before_configs["products"]
say_recipe 'Products'

config = {}
config['category'] = yes_wizard?("Would you like to include Product Category?") if true && true unless config.key?('category')
config['brand'] = yes_wizard?("Would you like to include Product Brand?") if true && true unless config.key?('brand')
config['product'] = yes_wizard?("Would you like to include Product?") if true && true unless config.key?('product')

config['shopping_cart'] = yes_wizard?("Would you like to add Cart Management?") if true && true unless config.key?('shopping_cart')

@configs[@current_recipe] = config

#if config['product']
  after_bundler do
    if config['product']
      say_wizard "Adding Product options"
      generate(:model, "product name:string description:string price:string #{(config['brand'])? "brand_id:string" : "" }")
    end
    if config['brand']
      say_wizard "Adding Brand options"
      generate "model brand name:string description:string"
      
      gsub_file 'app/models/product.rb', 'ActiveRecord::Base' do
        "ActiveRecord::Base
  belongs_to :brand"
      end
      gsub_file 'app/models/brand.rb', 'ActiveRecord::Base' do
        "ActiveRecord::Base
  has_many :products"
      end
    end
    
    if config['category']
      say_wizard "Adding Product Category options"
      generate "model category name:string description:string"
      generate "model category_product id:integer product_id:integer category_id:integer"
      gsub_file 'app/models/category.rb', 'ActiveRecord::Base' do
        "ActiveRecord::Base
  has_and_belongs_to_many :products, :join_table => :category_products"
      end
      gsub_file 'app/models/product.rb', 'ActiveRecord::Base' do
        "ActiveRecord::Base
  has_and_belongs_to_many :categories, :join_table => :category_products"
      end
      gsub_file 'app/models/category_product.rb', 'ActiveRecord::Base' do 
        "ActiveRecord::Base
  belongs_to :category
  belongs_to :product"
      end
    end
    
    if config['shopping_cart']
      # say_wizard "Adding Cart Management options"
      # generate(:model, "product name:string description:string price:string #{(config['brand'])? "brand_id:string" : "" }")
    end
  
#else
recipes.delete('products')


# >-----------------------------[ Configurations]-----------------------------------<

say_recipe 'Configuration File'
after_bundler do
  say_wizard "Generate Configuration Model"
  generate "model configuration name:string description:string"
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

# >-----------------------------[ Sitemap Generator ]-------------------------------<
@current_recipe = "sitemap_generator"
@before_configs["sitemap_generator"].call if @before_configs["sitemap_generator"]
say_recipe 'Sitemap Generator'

@configs[@current_recipe] = config

gem 'sitemap_generator'

after_bundler do
  run "rake sitemap:install"
  
end

# >-----------------------------[ Cleanup ]-------------------------------<
@current_recipe = "cleanup"
@before_configs["cleanup"].call if @before_configs["cleanup"]
say_recipe 'Clean Up'

after_bundler do
  # delete public/index.html
  remove_file 'public/index.html'
  
  # run the generated migrations
  run 'bundle exec rake db:migrate'
  
  # convert primary layout to haml
  run 'html2haml app/views/layouts/application.html.erb app/views/layouts/application.html.haml'
  remove_file 'app/views/layouts/application.html.erb'
  
  # generate the Home controller
  run 'bundle exec rails g controller Home index'
  
  # make home#index as root
  gsub_file 'config/routes.rb', /devise_for :users/ do
    "
    devise_for :users
    root :to => 'home#index'
    "
  end
  
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
  
  say_wizard "Add Sitemap to Robots.txt"
  append_file 'public/robots.txt' do
<<-'RailsAdminConfig'
Sitemap: http://www.example.com/sitemap_index.xml.gz
RailsAdminConfig
  end
  
end

@current_recipe = nil




# >-----------------------------[ Run Bundler ]-------------------------------<

say_wizard "Running Bundler install. This will take a while."
run 'bundle install'
say_wizard "Running after Bundler callbacks."
@after_blocks.each{|b| config = @configs[b[0]] || {}; @current_recipe = b[0]; b[1].call}

@current_recipe = nil
say_wizard "Running after everything callbacks."
@after_everything_blocks.each{|b| config = @configs[b[0]] || {}; @current_recipe = b[0]; b[1].call}
