# Homebrew formula for airev.
#
# Usage once published (see PUBLISHING.md):
#   brew install Dshuishui/tap/airev
#
# The sha256 below must match the GitHub-generated release tarball for the tag.
# After `git tag vX.Y.Z && git push --tags`, fill it in with:
#   curl -fsSL https://github.com/Dshuishui/airev/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
class Airev < Formula
  desc "AI code review before you push, using your logged-in AI CLI"
  homepage "https://github.com/Dshuishui/airev"
  url "https://github.com/Dshuishui/airev/archive/refs/tags/v0.6.0.tar.gz"
  version "0.6.0"
  sha256 "REPLACE_WITH_RELEASE_TARBALL_SHA256"
  license "MIT"

  def install
    bin.install "airev"
  end

  test do
    assert_match "airev 0.6.0", shell_output("#{bin}/airev version")
  end
end
