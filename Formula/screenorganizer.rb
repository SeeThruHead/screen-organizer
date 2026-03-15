class Screenorganizer < Formula
  desc "Menu bar app that auto-compresses screenshots and screen recordings"
  homepage "https://github.com/SeeThruHead/screen-organizer"
  url "https://github.com/SeeThruHead/screen-organizer/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "ab2a31ec3ccf0611c4f09ae13965a3278ca7c628b88961e5d507321c3ba18174"
  license "MIT"

  depends_on :macos
  depends_on "ffmpeg"
  depends_on "imagemagick"

  def install
    system "pkill", "-f", "ScreenOrganizer" if system("pgrep", "-f", "ScreenOrganizer", [:out, :err] => "/dev/null")
    mkdir_p "build"
    system "swiftc", "-o", "build/ScreenOrganizer",
           "ScreenOrganizer/main.swift",
           "ScreenOrganizer/AppDelegate.swift",
           "ScreenOrganizer/StatusBarController.swift",
           "ScreenOrganizer/FileWatcher.swift",
           "ScreenOrganizer/FileProcessor.swift",
           "ScreenOrganizer/DateOrganizer.swift",
           "ScreenOrganizer/Config.swift",
           "-framework", "Cocoa",
           "-framework", "CoreServices",
           "-O"

    app_dir = prefix/"Screen Organizer.app/Contents"
    (app_dir/"MacOS").mkpath
    cp "build/ScreenOrganizer", app_dir/"MacOS/ScreenOrganizer"
    cp "ScreenOrganizer/Info.plist", app_dir/"Info.plist"

    inreplace app_dir/"Info.plist" do |s|
      s.gsub! "$(PRODUCT_BUNDLE_IDENTIFIER)", "com.shanekeulen.screenorganizer"
      s.gsub! "$(EXECUTABLE_NAME)", "ScreenOrganizer"
      s.gsub! "$(PRODUCT_NAME)", "Screen Organizer"
      s.gsub! "$(PRODUCT_BUNDLE_PACKAGE_TYPE)", "APPL"
      s.gsub! "$(MARKETING_VERSION)", version.to_s
      s.gsub! "$(CURRENT_PROJECT_VERSION)", "1"
      s.gsub! "$(MACOSX_DEPLOYMENT_TARGET)", "11.0"
      s.gsub! "$(DEVELOPMENT_LANGUAGE)", "en"
    end
  end

  def post_install
    system "ln", "-sf", "#{prefix}/Screen Organizer.app", "/Applications/Screen Organizer.app"
    system "open", "/Applications/Screen Organizer.app"
  end

  def caveats
    <<~EOS
      Screen Organizer has been installed and symlinked to /Applications.

      To launch now:
        open "/Applications/Screen Organizer.app"

      Enable "Open at Login" from the menu bar icon.

      Configuration file: ~/.config/screenorganizer
    EOS
  end

  test do
    assert_predicate prefix/"Screen Organizer.app/Contents/MacOS/ScreenOrganizer", :executable?
  end
end
