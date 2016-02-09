# motion-screenshots

Automate your App Store screenshots with `rake screenshots`. Powered by [KSScreenshotManager](https://github.com/ksuther/KSScreenshotManager).

Check out some [sample output](https://github.com/usepropeller/motion-screenshots/tree/master/sample/screenshots/1389485329).

## Installation

Add this line to your application's Gemfile:

    gem 'motion-screenshots'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install motion-screenshots
    
And require in your Rakefile with:

    require "motion-screenshots"

## Usage

### Configuration

You can add blocks to be called when executing `rake screenshots`

- `app.before_screenshots do` - add this block in your Rakefile
- `app.after_screenshots do |output_path|` - add this block in your Rakefile

One useful way to use a `before_screenshots` block is to compile certain files outside the `app` directory only when taking screenshots:

```ruby  
app.before_screenshots do
  app.files += Dir.glob('screenshots/*.rb')
end
```

You can also do additional post-processing of your screenshots in your `after_screenshots` blocks.

#### Screnshots directory

By default, screenshots will be placed in a `./screenshots/#{timestamp}` directory in your project. You can configure this a few different ways:

- `ENV['SCREENSHOTS_DIR']` - use this environment variable
- `app.screenshots_output_path=` - set this value in your Rakefile

#### Simulators and languages

- `app.screenshots_config=` - set this value in your Rakefile

```ruby
app.screenshots_config = {
  devices: [
      "iPhone 4s",
      "iPhone 5",
      "iPhone 6",
      "iPhone 6 Plus"
  ],
  languages: [
      "en_US",
      "es_ES",
      "es_MX"
  ],
}
```

You can choose to take screenshots for different device sizes and languages that will be placed in `./#{screenshots_dir}/#{timestamp}/#{language}/#{device_name}`.

The device names correspond to simulator devices that you can configure in Xcode going to `Window > Devices`.

The `languages` array contains string of the form `language_COUNTRY`. To view a list of supported locales, run this code in the simulator:

```ruby
locale = NSLocale.alloc.initWithLocaleIdentifier("en_US")
NSLocale.availableLocaleIdentifiers.each do |identifier|
  name = locale.displayNameForKey(NSLocaleIdentifier, value: identifier)
  puts "#{identifier}\t\t#{name}"
end
```

### Status bar

You can also configure wether the status bar is included in the screenshots (not included by default).

- `app.screenshots_include_status_bar=` - set this value in your Rakefile

Additionally, using the included [SimulatorStatusMagic](https://github.com/shinydevelopment/SimulatorStatusMagic) library, you can set a perfect status bar. Just run the following somewhere before taking the screenshots:

```ruby
SDStatusBarManager.sharedInstance.enableOverrides
```

### Code

Create one or more subclasses of `Motion::Screenshots::Base`. This class uses a DSL you can use to setup what happens before and after various screenshots are taken.

```ruby
class AppScreenshots < Motion::Screenshots::Base

  # Use `.screenshot` to take a synchronous shot
  screenshot "menu" do
    before do
      # scroll down for a nice action shot
      App.delegate.table_view_controller.scrollToRowAtIndexPath(
        NSIndexPath.indexPathForRow(2, inSection: 1),
        animated: false,
        scrollPosition: UITableViewScrollPositionMiddle
      )
    end
  end

  # Use `.async_screenshot` to take a screenshot
  # at some point in the future (i.e. a timer, network calls, etc)
  # Invoke `#ready!` to take the shot
  async_screenshot "profile" do
    ready_delay 3 # delays the screenshot to 3 seconds after ready! is called

    before do
      App.delegate.table_view_controller.selectRowAtIndexPath(
        NSIndexPath.indexPathForRow(0, inSection: 1),
        animated: false,
        scrollPosition: UITableViewScrollPositionNone
      )

      ready!
    end

    # clean-up
    after do
      App.window.rootViewController.popViewControllerAnimated(false)
    end
  end
end
```

Then, after your initial views have appeared, simply let motion-screenshots know when to start the process:

```ruby
class MyFirstViewController

  def viewDidAppear(animated)
    super
 
    # May need to wrap in a Dispatch::Queue.main.async{} block
    if ENV['MOTION_SCREENSHOTS_RUNNING']
      AppScreenshots.start!
    end
  end
end
```

Screenshots are executed in the order listed in your class - doing any cleanup or pre-screenshot preparation is left to you.

### Running

Simple run `rake screenshots` and you're off! The task will uninstall and reinstall your CocoaPods, as to not include any of the private APIs bundled with `KSScreenshotManager`.

## Contact

[Clay Allsopp](http://clayallsopp.com/)
[@clayallsopp](https://twitter.com/clayallsopp)
