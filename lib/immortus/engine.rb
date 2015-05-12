module Immortus
  module Rails
    class Engine < ::Rails::Engine
      initializer 'immortus.assets.precompile' do |app|
        app.config.assets.paths << root.join('assets', 'javascripts').to_s
      end
    end
  end
end
