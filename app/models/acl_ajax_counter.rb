class AclAjaxCounter < ActiveRecord::Base
  serialize :options
  def self.all_tokens
    @all ||= AclAjaxCounter.all.inject({}) { |h, it| h[it.token] = it; h }
  end

  def self.[](token)
    self.all_tokens[token]
  end

  def self.[]=(token, value)
    ac = self.where(token: token).first_or_initialize
    ac.options = value
    ac.save
    self.all_tokens[token] = value
  end

  def [](name)
    (self.options || {})[name]
  end
end