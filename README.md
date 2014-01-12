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

## Usage

### Configuration

By default, screenshots will be placed in a `./screenshots/#{timestamp}` directory in your project. You can configure this a few different ways:

- `ENV['SCREENSHOTS_DIR']` - use this environment variable
- `app.screenshots_output_path=` - set this value in your Rakefile
- `app.manage_screenshots do |output_path|` - add this block in your Rakefile

### Code

Create one or more subclasses of `Motion::Screenshots::Base` and add them to `./app/screenshots`. This class uses a DSL you can use to setup what happens before and after various screenshots are taken.

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
    before do
      App.delegate.table_view_controller.selectRowAtIndexPath(
        NSIndexPath.indexPathForRow(0, inSection: 1),
        animated: false,
        scrollPosition: UITableViewScrollPositionNone
      )

      # give the network some time...
      Dispatch::Queue.main.after(3) {
        ready!
      }
    end

    # clean-up
    after do
      App.window.rootViewController.popViewControllerAnimated(false)
    end
  end
end
```

Then, elsewhere in your code, simply let motion-screenshots know when to start the process:

```ruby
class AppDelegate

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    # do other stuff...

    AppScreenshots.start!
  end
end
```

Screenshots are executed in the order listed in your class - doing any cleanup or pre-screenshot preparation is left to you.

### Running

Simple run `rake screenshots` and you're off! The task will uninstall and reinstall your CocoaPods, as to not include any of the private APIs bundled with `KSScreenshotManager`.

## Contact

[Clay Allsopp](http://clayallsopp.com/)
[@clayallsopp](https://twitter.com/clayallsopp)
