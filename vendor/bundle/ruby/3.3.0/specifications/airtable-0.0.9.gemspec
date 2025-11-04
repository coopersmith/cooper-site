# -*- encoding: utf-8 -*-
# stub: airtable 0.0.9 ruby lib

Gem::Specification.new do |s|
  s.name = "airtable".freeze
  s.version = "0.0.9".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nathan Esquenazi".freeze, "Alexander Sorokin".freeze]
  s.date = "2016-10-18"
  s.description = "Easily connect to airtable data using ruby with access to all of the airtable features.".freeze
  s.email = ["nesquena@gmail.com".freeze, "syrnick@gmail.com".freeze]
  s.homepage = "https://github.com/nesquena/airtable-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.2.2".freeze
  s.summary = "Easily connect to airtable data using ruby".freeze

  s.installed_by_version = "3.6.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<httparty>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.6".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.6.0".freeze])
  s.add_development_dependency(%q<fakeweb>.freeze, ["~> 1.3".freeze])
  s.add_development_dependency(%q<activesupport>.freeze, [">= 3.0".freeze])
end
