Rails.application.routes.draw do
  get 'welcome/index'

  immortus_jobs do
    get 'welcome/wait', to: 'welcome#wait'
  end

  root 'welcome#index'
end
