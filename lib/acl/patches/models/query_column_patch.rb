module Acl::Patches::Models
  module QueryColumnPatch
    def groupable
      @groupable.is_a?(Proc) ? @groupable.call : @groupable
    end
  end
end