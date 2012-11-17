# these routes are getting ingored for some reason so
# they still exist in the host spreecommerce.com app
#
Rails.application.routes.prepend do
  namespace :add_on do
    resources :deploys do
      resources :servers, :except => [:new, :index]
      member do
        get 'capistrano'
      end
    end
  end

  match '/puppet/classify', :to => 'puppet_integration#classify'
  match '/puppet/report', :to => 'puppet_integration#report'

end
