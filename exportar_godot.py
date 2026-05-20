import os
import sys

# ============================================================
#  EXPORTAR PROJETO GODOT — EMBERVEIL
#  Coloca esse arquivo na RAIZ do projeto e roda com Python
# ============================================================

EXTENSOES = [".gd", ".tscn", ".tres"]  # arquivos que serão lidos
SAIDA = "emberveil_export.txt"          # nome do arquivo gerado
IGNORAR_PASTAS = {".godot", ".git", "addons"}  # pastas ignoradas

def exportar_projeto():
    raiz = os.path.dirname(os.path.abspath(__file__))
    linhas = []
    arquivos_encontrados = 0

    linhas.append("=" * 60)
    linhas.append("  EMBERVEIL — EXPORT COMPLETO DO PROJETO")
    linhas.append("=" * 60)
    linhas.append("")

    for dirpath, dirnames, filenames in os.walk(raiz):
        # Remove pastas ignoradas da busca
        dirnames[:] = [d for d in dirnames if d not in IGNORAR_PASTAS]

        for filename in sorted(filenames):
            _, ext = os.path.splitext(filename)
            if ext not in EXTENSOES:
                continue

            filepath = os.path.join(dirpath, filename)
            caminho_relativo = os.path.relpath(filepath, raiz)

            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    conteudo = f.read()
            except Exception as e:
                conteudo = f"[ERRO AO LER ARQUIVO: {e}]"

            linhas.append("=" * 60)
            linhas.append(f"ARQUIVO: {caminho_relativo}")
            linhas.append("=" * 60)
            linhas.append(conteudo)
            linhas.append("")
            arquivos_encontrados += 1

    # Resumo no final
    linhas.append("=" * 60)
    linhas.append(f"TOTAL DE ARQUIVOS EXPORTADOS: {arquivos_encontrados}")
    linhas.append("=" * 60)

    saida_path = os.path.join(raiz, SAIDA)
    with open(saida_path, "w", encoding="utf-8") as f:
        f.write("\n".join(linhas))

    print(f"\n✅ Exportação concluída!")
    print(f"📄 Arquivo gerado: {saida_path}")
    print(f"📦 Total de arquivos: {arquivos_encontrados}")

if __name__ == "__main__":
    exportar_projeto()
