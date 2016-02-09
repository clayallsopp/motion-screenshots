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
        instance_eval(&eval_block) if eval_block
      end

      def before(&actions)
        @before_actions = actions
      end

      def after(&actions)
        @after_actions = actions
      end

      def ready!
        if @delay
          Dispatch::Queue.main.after(@delay.to_f) {
            @manager.actionIsReady
          }
        else
          @manager.actionIsReady
        end
      end

      def ready_delay(amount)
        @delay = amount
      end

      def to_KSScreenshotAction
        action = KSScreenshotAction.actionWithName(@title, asynchronous: @is_async,
          actionBlock:-> { @before_actions.call if @before_actions },
          cleanupBlock: -> { @after_actions.call if @after_actions }
        )
        action.includeStatusBar = true if ENV['SCREENSHOTS_INCLUDE_STATUSBAR']
        action
      end
    end
  end
end
