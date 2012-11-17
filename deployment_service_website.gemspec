$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "deployment_service_website/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "deployment_service_website"
  s.version     = DeploymentServiceWebsite::VERSION
  s.authors     = ["Beian Quinn"]
  s.email       = ["brian@spreecommerce.com"]
  s.homepage    = "spreecommerce.com"
  s.summary     = "Web UI for Spree Deployment Service."
  s.description = "Engine that integrates with main spreecommerce.com application, to provide UI for deployment service."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
end
