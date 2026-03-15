class ScreenOrganizer < Formula
  desc "Menu bar app that auto-compresses screenshots and screen recordings"
  homepage "https://github.com/SeeThruHead/screen-organizer"
  url "https://github.com/SeeThruHead/screen-organizer/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256"
  license "MIT"

  depends_on :macos
  depends_on "ffmpeg"
  depends_on "imagemagick"

  def install
    system "swiftc", "-o", "ScreenOrganizer",
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

    # Create .app bundle
    app_dir = prefix/"Screen Organizer.app/Contents"
    (app_dir/"MacOS").mkpath
    cp "ScreenOrganizer", app_dir/"MacOS/ScreenOrganizer"
    cp "ScreenOrganizer/Info.plist", app_dir/"Info.plist"

    # Fill in Info.plist placeholders
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
    # Symlink into /Applications so it shows up in Spotlight/Launchpad
    app = prefix/"Screen Organizer.app"
    target = Pathname("/Applications/Screen Organizer.app")
    target.unlink if target.symlink?
    target.make_symlink(app)
  end

  def caveats
    <<~EOS
      Screen Organizer has been installed and symlinked to /Applications.

      To start at login:
        System Settings → General → Login Items → add "Screen Organizer"

      To launch now:
        open "/Applications/Screen Organizer.app"

      Configuration file: ~/.config/screenorganizer
    EOS
  end

  test do
    assert_predicate prefix/"Screen Organizer.app/Contents/MacOS/ScreenOrganizer", :executable?
  end
end
