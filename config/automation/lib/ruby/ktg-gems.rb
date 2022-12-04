# frozen_string_literal: true

gemfile do
  source "https://rubygems.org/"

  # keep in sync with Gemfile's :rules group
  gem "activesupport", "~> 6.1", require: false
end

require "active_support/core_ext/object/blank"
