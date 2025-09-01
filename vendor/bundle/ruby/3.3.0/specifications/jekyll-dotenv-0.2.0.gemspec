# -*- encoding: utf-8 -*-
# stub: jekyll-dotenv 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "jekyll-dotenv".freeze
  s.version = "0.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://0xacab.org/sutty/jekyll/jekyll-dotenv/issues", "changelog_uri" => "https://0xacab.org/sutty/jekyll/jekyll-dotenv/-/blob/master/CHANGELOG.md", "documentation_uri" => "https://rubydoc.info/gems/jekyll-dotenv", "homepage_uri" => "https://0xacab.org/sutty/jekyll/jekyll-dotenv", "source_code_uri" => "https://0xacab.org/sutty/jekyll/jekyll-dotenv" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["f".freeze]
  s.date = "2021-01-19"
  s.description = "Use environment variables in Jekyll themes".freeze
  s.email = ["f@sutty.nl".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "LICENSE.txt".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://0xacab.org/sutty/jekyll/jekyll-dotenv".freeze
  s.licenses = ["GPL-3.0".freeze]
  s.rdoc_options = ["--title".freeze, "jekyll-dotenv - Environment variables in Jekyll".freeze, "--main".freeze, "README.md".freeze, "--line-numbers".freeze, "--inline-source".freeze, "--quiet".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Environment variables in Jekyll".freeze

  s.installed_by_version = "3.6.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<jekyll>.freeze, ["~> 4".freeze])
  s.add_runtime_dependency(%q<dotenv>.freeze, ["~> 2.7".freeze])
end
