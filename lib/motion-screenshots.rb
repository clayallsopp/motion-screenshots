unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

require 'motion-cocoapods'
require 'fileutils'
require 'shellwords'
require 'json'
require 'fix_simulator_zoom'

lib_dir_path = File.dirname(File.expand_path(__FILE__))
module Motion; module Project; class Config
  attr_accessor :screenshot_callback, :is_taking_screenshots

  variable :screenshots_output_path,
           :screenshots_include_status_bar,
           :screenshots_config

  def before_screenshots(&block)
    if is_taking_screenshots
      block.call
    end
  end

  def after_screenshots(&block)
    @screenshot_callback = block
  end

  alias_method :manage_screenshots, :after_screenshots
end; end; end

namespace 'screenshots' do
  task :start do
    fix_simulator_zoom

    app_config = Motion::Project::App.config_without_setup
    app_config.is_taking_screenshots = true
    ENV['MOTION_SCREENSHOTS_RUNNING'] = '1'

    gem_files = Dir.glob(File.join(lib_dir_path, "motion/**/*.rb"))
    app_config.files.unshift(gem_files).flatten!

    app_config.pods do
      pod 'KSScreenshotManager', :git => 'git://github.com/ksuther/KSScreenshotManager.git'
      pod 'SimulatorStatusMagic'
    end

    Motion::Project::App.info 'Pods', 'Intalling motion-screenshot dependencies'
    Rake::Task["pod:install"].invoke

    project_dir = File.expand_path(app_config.project_dir)
    screenshots_output_path = ENV['SCREENSHOTS_DIR']
    screenshots_output_path ||= App.config.screenshots_output_path
    screenshots_output_path ||= File.join(project_dir, "screenshots", Time.now.to_i.to_s)
    FileUtils.mkdir_p screenshots_output_path

    at_exit {
      Motion::Project::App.info 'Pods', 'Removing motion-screenshot dependencies'
      system("env COCOAPODS_NO_REPO_UPDATE=1 bundle exec rake pod:install")
      `open "#{screenshots_output_path.shellescape}"`
    }

    config = App.config.screenshots_config

    if config
      ENV['SCREENSHOTS_INCLUDE_STATUSBAR'] = '1' if App.config.screenshots_include_status_bar
      config[:devices].each do |device|
        config[:languages].each do |lang|
          localized_output_path = File.join(screenshots_output_path, lang, device)
          FileUtils.mkdir_p localized_output_path
          ENV['SCREENSHOTS_PATH'] = localized_output_path

          ENV['device_name'] = device
          ENV['args'] = "-AppleLanguages '(#{lang.split('_').first})' -AppleLocale '#{lang}'"

          Rake::Task["simulator"].execute
        end
      end
    else
      ENV['SCREENSHOTS_PATH'] = screenshots_output_path
      Rake::Task["simulator"].execute
    end
  end
end

desc "Take screenshots in your app"
task :screenshots => "screenshots:start"
