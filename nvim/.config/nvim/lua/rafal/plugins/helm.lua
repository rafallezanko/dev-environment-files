-- Wykrywanie filetype dla wykresów Helm (Chart.yaml, values.yaml, templates/*.yaml
-- → ft=helm). Bez tego nvim trzyma je jako yaml, helm_ls się nie podłącza, a
-- prettier/yaml-ls psuje szablony Go. helm_ls instaluje Mason (ensure_installed).
return {
  "towolf/vim-helm",
  event = { "BufReadPre", "BufNewFile" },
}
