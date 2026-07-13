#!/usr/bin/env ruby
# frozen_string_literal: true

# Regenerates the Ruby/Rails shields.io badge lines in a gem's README.md
# from its own gemspec, so they can never silently drift out of sync with
# the actual required_ruby_version / rails dependency (as happened in
# midas: README/CLAUDE.md/docs all claimed "Ruby >= 3.4" for months after
# the gemspec was deliberately lowered to >= 3.2.0).
#
# Intentionally does NOT touch the Gem Version or CI badges — those
# already query live services (badge.fury.io, GitHub Actions) and can't
# drift on their own.
#
# Canonical copy lives in whittakertech/.github; per-repo Gitea Actions
# workflows fetch and run this directly (Gitea can't resolve cross-repo
# reusable workflow references, so this can't be a `uses:` reusable
# workflow like ruby-ci.yml/release-gem.yml — see that history for why).
#
# Exits 0 whether or not anything changed; the calling workflow diffs
# README.md itself to decide whether to commit.

require 'rubygems'

def major_minor(requirement_string)
  match = requirement_string.match(/(\d+)\.(\d+)/)
  raise "Could not parse a version out of #{requirement_string.inspect}" unless match

  "#{match[1]}.#{match[2]}"
end

gemspec_path = Dir['*.gemspec'].first
unless gemspec_path
  warn 'No gemspec found in the current directory — nothing to sync.'
  exit 0
end

spec = Gem::Specification.load(gemspec_path)

ruby_requirement = spec.required_ruby_version.to_s
ruby_version = major_minor(ruby_requirement)

rails_dependency = spec.dependencies.find { |d| d.name == 'rails' }
unless rails_dependency
  warn "#{gemspec_path} has no 'rails' dependency — leaving the Rails badge untouched."
end
rails_version = rails_dependency && major_minor(rails_dependency.requirement.to_s)

readme_path = 'README.md'
unless File.exist?(readme_path)
  warn 'No README.md found — nothing to sync.'
  exit 0
end

readme = File.read(readme_path)

readme = readme.gsub(
  %r{!\[Ruby [^\]]*\]\(https://img\.shields\.io/badge/ruby-[^)]*\)},
  "![Ruby #{ruby_version}](https://img.shields.io/badge/ruby-#{ruby_version}+-red.svg)"
)

if rails_version
  readme = readme.gsub(
    %r{!\[Rails [^\]]*\]\(https://img\.shields\.io/badge/rails-[^)]*\)},
    "![Rails #{rails_version}](https://img.shields.io/badge/rails-#{rails_version}+-crimson.svg)"
  )
end

File.write(readme_path, readme)
puts "Synced README badges: Ruby #{ruby_version}#{" / Rails #{rails_version}" if rails_version}"
