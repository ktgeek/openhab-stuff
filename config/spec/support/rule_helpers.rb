# frozen_string_literal: true

# Most rules in automation/ruby have no id, so `rules["id"]` can't find them and their name is all a spec has to go on.
module RuleHelpers
  def rule_named(name)
    rules.find { |rule| rule.name == name } || raise(ArgumentError, "No rule named #{name.inspect}")
  end
end

RSpec.configure { |config| config.include RuleHelpers }
