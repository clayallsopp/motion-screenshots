class GlobalTimelineViewController < UITableViewController
  attr_accessor :posts

  def reload
    self.navigationItem.rightBarButtonItem.enabled = true

    Post.fetchGlobalTimelinePosts do |posts, error|
      if (error)
        UIAlertView.alloc.initWithTitle("Error",
          message:error.localizedDescription,
          delegate:nil,
          cancelButtonTitle:nil,
          otherButtonTitles:"OK", nil).show
      else
        self.posts = posts
      end

      self.navigationItem.rightBarButtonItem.enabled = true
    end
  end

  def posts
    @posts ||= []
  end

  def posts=(posts)
    @posts = posts
    self.tableView.reloadData
    @posts
  end

  def viewDidLoad
    super

    self.title = "Global Timeline"

    self.navigationItem.rightBarButtonItem = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemRefresh, target:self, action: 'reload')

    self.tableView.rowHeight = 70

    self.reload
  end

  def tableView(tableView, numberOfRowsInSection:section)
    self.posts.count
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    @@identifier ||= "Cell"

    cell = tableView.dequeueReusableCellWithIdentifier(@@identifier) || begin
      PostTableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:@@identifier)
    end

    cell.post = self.posts[indexPath.row]
  
    cell
  end

  def tableView(tableView, heightForRowAtIndexPath:indexPath)
    PostTableViewCell.heightForCellWithPost(self.posts[indexPath.row])
  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    tableView.deselectRowAtIndexPath(indexPath, animated:true)
  end
end