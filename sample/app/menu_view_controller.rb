class MenuViewController < UITableViewController

  def viewDidLoad
    self.title = "AppDotNet"
  end

  def viewDidAppear(animated)
    super

    # Account for transition time
    Dispatch::Queue.main.after(0.3) {
      AppScreenshots.start!
    }
  end

  def tableView(tableView, numberOfRowsInSection:section)
    3
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    @@identifier ||= "MenuCell"

    cell = tableView.dequeueReusableCellWithIdentifier(@@identifier) || begin
      UITableViewCell.alloc.initWithStyle(UITableViewCellStyleValue1, reuseIdentifier:@@identifier)
    end

    case indexPath.row
    when 0
      cell.textLabel.text = "Global Timeline"
    when 1
      cell.textLabel.text = "My Profile"
    when 2
      cell.textLabel.text = "Settings"
    end

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator

    cell
  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    tableView.deselectRowAtIndexPath(indexPath, animated:true)

    vc = GlobalTimelineViewController.alloc.initWithStyle(UITableViewStylePlain)
    UIWindow.keyWindow.rootViewController.pushViewController(vc, animated:true)
  end
end