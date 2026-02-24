return {
  {
    "nvim-neotest/neotest",
    cmd = { "Neotest" },
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-neotest/neotest-python",
      "fredrikaverpil/neotest-golang",
      {
        "rcasia/neotest-java",
        dependencies = {
          "mfussenegger/nvim-jdtls",
        },
      },
      "codymikol/neotest-kotlin",
      "stevanmilic/neotest-scala",
    },
    config = function()
      local config = {
        runner = "go",
      }
      local function ensure_neotest_java_jar()
        local jar_dir = vim.fn.stdpath("data") .. "/neotest-java"
        local jar_version = "6.0.2"
        local jar_name = "junit-platform-console-standalone-" .. jar_version .. ".jar"
        local jar_path = jar_dir .. "/" .. jar_name
        if vim.fn.filereadable(jar_path) == 1 then
          return jar_path
        end

        vim.fn.mkdir(jar_dir, "p")
        local url = "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/"
          .. jar_version
          .. "/"
          .. jar_name
        local cmd = {
          "curl",
          "-L",
          "-o",
          jar_path,
          url,
        }

        local result = vim.system(cmd):wait()
        if result.code ~= 0 then
          vim.notify(
            "neotest-java: failed to download JUnit jar. Please download it manually:\n" .. url,
            vim.log.levels.ERROR
          )
          return nil
        end

        return jar_path
      end

      local function scala_runner()
        local cwd = vim.fn.getcwd()
        if
          vim.fn.filereadable(cwd .. "/build.sbt") == 1
          or vim.fn.filereadable(cwd .. "/project/build.properties") == 1
        then
          return "sbt"
        end
        if vim.fn.isdirectory(cwd .. "/.bloop") == 1 then
          return "bloop"
        end
        return "bloop"
      end
      require("neotest").setup({
        adapters = {
          require("neotest-python"),
          require("neotest-golang")(config),
          require("neotest-java")({
            junit_jar = ensure_neotest_java_jar(),
          }),
          require("neotest-kotlin"),
          require("neotest-scala")({
            framework = "scalatest",
            runner = scala_runner,
          }),
        },
      })
    end,
  },
}
