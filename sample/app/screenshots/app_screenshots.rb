class AppScreenshots < Motion::Screenshots::Base
  screenshot 'menu'

  async_screenshot 'timeline' do
    before do
      vc = UIApplication.sharedApplication.delegate.menu_controller
      tv = vc.tableView
      vc.tableView(
        tv,
        didSelectRowAtIndexPath: NSIndexPath.indexPathForRow(0, inSection:0)
      )

      # give the network some time...
      Dispatch::Queue.main.after(3) {
        ready!
      }
    end
  end
end