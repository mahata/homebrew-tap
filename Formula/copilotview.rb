class Copilotview < Formula
  desc "Browse, search and summarize past GitHub Copilot CLI and app sessions"
  homepage "https://github.com/mahata/copilotview"
  url "https://github.com/mahata/copilotview/releases/download/v0.14.0/copilotview-0.14.0.tar.gz"
  sha256 "b25947a00856c402e89cca5860e1469a1399a2c53010eacba9af24970c76c16b"
  license "MIT"

  depends_on "node"

  def install
    libexec.install "cli.js", "web", "VERSION"
    (bin/"copilotview").write <<~SH
      #!/bin/bash
      exec "#{formula_opt_bin("node")}/node" "#{libexec}/cli.js" "$@"
    SH
    bin.install_symlink bin/"copilotview" => "cv"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/copilotview --version")

    (testpath/"sessions").mkpath
    system bin/"copilotview", "index", "--source", testpath/"sessions", "--index", testpath/"index.db"
    assert_match "Sessions:   0", shell_output("#{bin}/copilotview stats --index #{testpath}/index.db")
    assert_match "Sessions:   0", shell_output("#{bin}/cv stats --index #{testpath}/index.db")

    port = free_port
    pid = spawn bin/"copilotview", "serve", "--source", testpath/"sessions", "--index", testpath/"index.db",
                "--port", port.to_s
    url = "http://127.0.0.1:#{port}/"
    assert_match "<title>copilotview</title>",
                 shell_output("curl -fsS --retry 10 --retry-connrefused --retry-delay 1 #{url}")
  ensure
    if pid
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
