#!/usr/bin/env Rscript
# グローバル R パッケージのインストール (冪等)
#
# 使い方:
#   Rscript install-global-packages.R
#
# pak は他のパッケージのインストーラとして使うため最初にブートストラップする。

repos <- "https://cloud.r-project.org"

# pak を install.packages() でブートストラップ (鶏と卵問題のため)
if (!requireNamespace("pak", quietly = TRUE)) {
  message("Bootstrapping pak...")
  install.packages("pak", repos = repos)
}

# グローバルに入れたいパッケージ
packages <- c(
  "renv",          # プロジェクトごとの依存固定
  "knitr",         # Quarto / R Markdown のコードチャンク実行エンジン
  "rmarkdown",     # Quarto が HTML レンダリング時に内部で利用
  "yaml",          # renv が .qmd の YAML frontmatter から依存を検出するのに必要
  "languageserver" # Positron / VS Code の R LSP
)

installed <- rownames(installed.packages())
to_install <- setdiff(packages, installed)

if (length(to_install) > 0) {
  message("Installing: ", paste(to_install, collapse = ", "))
  pak::pkg_install(to_install)
} else {
  message("All global R packages already installed.")
}
