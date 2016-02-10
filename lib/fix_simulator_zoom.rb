# The MIT License (MIT)

# Copyright (c) 2015 Felix Krause

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# This fix is needed due to a bug in UI Tests that creates invalid screenshots when the
# simulator is not scaled to a 100%
# Radar: https://openradar.appspot.com/radar?id=6127019184095232

require 'open3'

def fix_simulator_zoom
  @devices = []
  os_type = 'unknown'
  os_version = 'unknown'
  output = ''
  Open3.popen3('xcrun simctl list devices') do |stdin, stdout, stderr, wait_thr|
    output = stdout.read
  end

  output.split(/\n/).each do |line|
    next if line.match(/^== /)
    if line.match(/^-- /)
      (os_type, os_version) = line.gsub(/-- (.*) --/, '\1').split
    else
      # iPad 2 (0EDE6AFC-3767-425A-9658-AAA30A60F212) (Shutdown)
      # iPad Air 2 (4F3B8059-03FD-4D72-99C0-6E9BBEE2A9CE) (Shutdown) (unavailable, device type profile not found)
      match = line.match(/\s+([^\(]+) \(([-0-9A-F]+)\) \((?:[^\(]+)\)(.*unavailable.*)?/)
      if match && !match[3] && os_type == 'iOS'
        @devices << { name: match[1], ios_version: os_version, udid: match[2] }
      end
    end
  end

  config_path = File.join(File.expand_path("~"), "Library", "Preferences", "com.apple.iphonesimulator.plist")

  # First we need to kill the simulator
  `killall iOS Simulator &> /dev/null`

  @devices.each do |simulator|
    simulator_name = simulator[:name].tr("\s", "-")
    key = "SimulatorWindowLastScale-com.apple.CoreSimulator.SimDeviceType.#{simulator_name}"

    command = "defaults write '#{config_path}' '#{key}' '1.0'"
    `#{command}`
  end
end

