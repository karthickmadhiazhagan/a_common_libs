# RubyEncoder bug
Rails.application.routes.draw do
  post 'ajax_counters/counters', to: 'ajax_counters#counters'
  get 'acl/upload_icons', controller: :acl_style_css, action: :upload_icons
  post 'acl/upload_icons', controller: :acl_style_css, action: :upload_icons

  resources :custom_fields do
    member do
      get 'ajax_values'
      get 'ajax_options'
    end
  end

  resources :api_log_for_plugins, only: [:index] do
    member do
      get 'log_served'
    end
  end

  resources :issues do
    member do
      get 'acl_cf_trimmed_all/:cf_id', action: :acl_cf_trimmed_all
      get 'acl_edit_form'
    end
  end
end