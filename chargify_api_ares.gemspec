Gem::Specification.new do |s|
  s.specification_version = 3 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.rubygems_version          = '1.3.7'

  s.name        = 'chargify_api_ares'
  s.version     = '1.4.19'
  s.date        = '2019-10-01'
  s.summary     = 'A Chargify API wrapper for Ruby using ActiveResource'
  s.description = ''
  s.authors     = ['Chargify Development Team']
  s.email       = 'dev@chargify.com'
  s.homepage    = 'http://github.com/chargify/chargify_api_ares'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = %w[lib]

  # Runtime Dependencies
  s.add_runtime_dependency('activeresource')

  # Development Dependencies
  s.add_development_dependency('appraisal')
  s.add_development_dependency('dotenv')
  s.add_development_dependency('factory_bot')
  s.add_development_dependency('faker')
  s.add_development_dependency('fakeweb', '~> 1.3.0')
  s.add_development_dependency('pry')
  s.add_development_dependency('rake')
  s.add_development_dependency('rexml')
  s.add_development_dependency('rspec')
  s.add_development_dependency('vcr', '~> 2.9.3')
end
