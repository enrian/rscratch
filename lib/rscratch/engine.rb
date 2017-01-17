require 'smart_listing'
require 'haml'
require 'ejs'
require 'jbuilder'

module Rscratch
  class Engine < ::Rails::Engine
    isolate_namespace Rscratch
    config.assets.precompile += %w( rscratch/rscratch_logo.png )
    config.assets.precompile += %w( rscratch/roboto/*.ttf )
    config.assets.precompile += %w( rscratch/iconfont/* )
  end
end
