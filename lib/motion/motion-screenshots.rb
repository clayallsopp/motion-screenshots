if !Kernel.const_defined?(:KSScreenshotManager)
  class KSScreenshotManager
    def init
      @started = true
    end
  end
end

module Motion
  module Screenshots
    class Base < KSScreenshotManager
      SCREENSHOTS_BASE_FOLDER = "motion_screenshots"
      class << self
        # Adds a namespace folder for this screenshot class
        def group_by(&block)
          shared.group_by_block = block
        end

        def async_screenshot(title, &block)
          shared.async_screenshot(title, &block)
        end

        def screenshot(title, &block)
          shared.screenshot(title, &block)
        end

        def start!
          shared.start!
        end

        private
          def shared
            @shared ||= alloc.init
          end
      end

      attr_accessor :group_by_block, :screenshot_groups

      def init
        super
        @group_by_block = nil
        @screenshot_groups = []
        self
      end

      def group_by(&block)
        @group_by_block = block
      end

      def async_screenshot(title, &block)
        @screenshot_groups << ScreenshotGroup.new(title, true, self, &block)
      end

      def screenshot(title, &block)
        @screenshot_groups << ScreenshotGroup.new(title, false, self, &block)
      end

      def setupScreenshotActions
        @screenshot_groups.each do |sg|
          addScreenshotAction sg.to_KSScreenshotAction
        end
      end

      def start!
        return if @started

        @started = true

        documents_path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0].retain
        screenshot_path = File.join(documents_path, SCREENSHOTS_BASE_FOLDER)
        screenshot_path = File.join(screenshot_path, group_by_block.call) if @group_by_block
        self.screenshotsURL = NSURL.fileURLWithPath(screenshot_path)

        takeScreenshots
      end
    end

    class ScreenshotGroup
      def initialize(title, is_async, manager, &eval_block)
        @title = title
        @is_async = is_async
        @manager = manager
        @before_actions = nil
        @after_actions = nil
        instance_eval(&eval_block)
      end

      def before(&actions)
        @before_actions = actions
      end

      def after(&actions)
        @after_actions = actions
      end

      def ready!
        @manager.actionIsReady
      end

      def to_KSScreenshotAction
        KSScreenshotAction.actionWithName(@title, asynchronous: @is_async,
          actionBlock:-> { @before_actions.call if @before_actions },
          cleanupBlock: -> { @after_actions.call if @after_actions }
        )
      end
    end
  end
end