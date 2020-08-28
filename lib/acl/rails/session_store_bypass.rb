module Acl::Rails
  class SessionStoreBypass < ActiveRecord::SessionStore::Session
    # to prevent saving session for API requests
    before_save do
      throw(:abort) if User.current.api_request?
    end
  end
end

if ActionDispatch::Session::ActiveRecordStore.session_class == ActiveRecord::SessionStore::Session
  ActionDispatch::Session::ActiveRecordStore.session_class = Acl::Rails::SessionStoreBypass
end

