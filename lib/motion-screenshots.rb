unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

require 'motion-cocoapods'
require 'motion-env'
require 'fileutils'
require 'shellwords'
require 'plist'

lib_dir_path = File.dirname(File.expand_path(__FILE__))
Motion::Project::App.setup do |app|
  gem_files = Dir.glob(File.join(lib_dir_path, "motion/**/*.rb"))
  app.files.unshift(gem_files).flatten!
end

module Motion; module Project; class Config
  attr_accessor :screenshot_callback, :is_taking_screenshots

  variable :screenshots_output_path

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
    app_config = Motion::Project::App.config_without_setup
    app_config.pods do
      pod 'KSScreenshotManager'
    end

    app_config.is_taking_screenshots = true
    app_config.env['MOTION_SCREENSHOTS_RUNNING'] = true

    if app_config.archs['iPhoneSimulator'].include? 'x86_64'
      # required until KSScreenshotManager is 64bit compatible
      App.warn 'Forcing 32bit-only build target for screenshots..'
      app_config.archs['iPhoneSimulator'] = %w(i386)
    end

    screenshots_output_path = ENV['SCREENSHOTS_DIR']
    screenshots_output_path ||= App.config.screenshots_output_path
    screenshots_output_path ||= File.join(`pwd`.strip, "screenshots", Time.now.to_i.to_s)
    FileUtils.mkdir_p screenshots_output_path

    at_exit {
      # Copy files
      app = app_config.app_bundle('iPhoneSimulator')
      app_id = app_config.identifier
      app_dir = nil
      
      if File.directory? File.expand_path( "~/Library/Developer/CoreSimulator/Devices" )
        # XCode 6+ uses the same random UUID layout to store applications and
        # application sandboxes as the native iOS device does (== more work..).
        sim_apps = File.expand_path("~/Library/Developer/CoreSimulator/Devices")
        app_dir = File.dirname(Dir.glob("#{sim_apps}/**/#{File.basename(app)}").sort_by{ |f|
          File.mtime(f)
        }.reverse.first)
        # Get the simulator UUID, then read it's application install data..
        sim_base = app_dir.gsub( %r{(^.*/Devices/\h{8}-(?:\h{4}-){3}\h{12})/.*}, '\\1' )
        app_infos = Plist::parse_xml(open("|plutil -convert xml1 -o - -- #{sim_base}/data/Library/BackBoard/applicationState.plist").read)
        # ..and finally determine the sandbox data directory
        app_dir = app_infos[app_config.identifier]['compatibilityInfo']['sandboxPath']
      else
        # pre XCode 6
        target = ENV['target'] || app_config.sdk_version
        sim_apps = File.expand_path("~/Library/Application Support/iPhone Simulator/*/Applications")
        app_dir = File.dirname(Dir.glob("#{sim_apps}/**/#{File.basename(app)}").sort_by { |f|
          File.mtime(f)
        }.reverse.first)
      end

      motion_screenshots = File.join(app_dir, "Documents", "motion_screenshots")
      screenshot_files = Dir[File.join(motion_screenshots, "**", "*")]
      FileUtils.cp_r(screenshot_files, screenshots_output_path)
      if app_config.screenshot_callback
        app_config.screenshot_callback.call(screenshots_output_path)
      else
        `open #{screenshots_output_path.shellescape}`
      end
      puts "Re-installing pods..."
      `bundle exec rake pod:install`
    }

    Rake::Task["pod:install"].invoke
    Rake::Task["default"].invoke
  end
end

desc "Take screenshots in your app"
task :screenshots => "screenshots:start"