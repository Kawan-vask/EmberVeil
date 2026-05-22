import os
import re

# ============================================================
#  EXPORTAR PROJETO GODOT — EMBERVEIL (OTIMIZADO)
#  Coloca esse arquivo na RAIZ do projeto e roda com Python
#
#  Melhorias em relação à versão anterior:
#  - .tscn: exporta apenas estrutura de nós e conexões (sem dados de mesh/material)
#  - .tres: exporta apenas arquivos da pasta Resources/ (dados relevantes)
#  - .gd:   exporta tudo (são o core do projeto)
#  - Ordem: scripts primeiro, depois cenas, depois resources
#  - Resultado: ~50% menos tokens sem perder informação útil
# ============================================================

SAIDA = "emberveil_export.txt"
IGNORAR_PASTAS = {".godot", ".git", "addons", "Assets"}

# Pastas onde .tres são relevantes
PASTAS_RESOURCES = {"Resources", "resources"}


def is_resource_relevante(caminho_relativo: str) -> bool:
    partes = caminho_relativo.replace("\\", "/").split("/")
    return any(p in PASTAS_RESOURCES for p in partes)


def filtrar_tscn(conteudo: str) -> str:
    """
    Extrai apenas as linhas relevantes de um .tscn:
    - [node ...] — estrutura da cena
    - [connection ...] — signals conectados
    - [ext_resource ...] — scripts e cenas referenciadas
    Remove dados pesados: transforms, meshes, materiais, sub_resources.
    """
    linhas_relevantes = []
    for linha in conteudo.splitlines():
        stripped = linha.strip()
        if (
            stripped.startswith("[node ")
            or stripped.startswith("[connection ")
            or stripped.startswith("[ext_resource ")
            or stripped.startswith("[gd_scene ")
        ):
            linhas_relevantes.append(linha)
        elif any(k in stripped for k in [
            "script =",
            "groups =",
            "collision_layer",
            "collision_mask",
            "enemy_scene",
            "night_config",
            "data =",
        ]):
            linhas_relevantes.append(linha)

    return "\n".join(linhas_relevantes)


def exportar_projeto():
    raiz = os.path.dirname(os.path.abspath(__file__))

    scripts   = []
    cenas     = []
    resources = []

    for dirpath, dirnames, filenames in os.walk(raiz):
        dirnames[:] = [d for d in dirnames if d not in IGNORAR_PASTAS]

        for filename in sorted(filenames):
            _, ext = os.path.splitext(filename)
            if ext not in (".gd", ".tscn", ".tres"):
                continue

            filepath = os.path.join(dirpath, filename)
            caminho_relativo = os.path.relpath(filepath, raiz)

            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    conteudo = f.read()
            except Exception as e:
                conteudo = f"[ERRO AO LER ARQUIVO: {e}]"

            if ext == ".gd":
                scripts.append((caminho_relativo, conteudo))
            elif ext == ".tscn":
                cenas.append((caminho_relativo, filtrar_tscn(conteudo)))
            elif ext == ".tres" and is_resource_relevante(caminho_relativo):
                resources.append((caminho_relativo, conteudo))

    linhas = []
    linhas.append("=" * 60)
    linhas.append("  EMBERVEIL — EXPORT COMPLETO DO PROJETO")
    linhas.append("=" * 60)
    linhas.append("")

    def escrever_secao(titulo, arquivos):
        if not arquivos:
            return
        linhas.append("")
        linhas.append("#" * 60)
        linhas.append(f"#  {titulo} ({len(arquivos)} arquivos)")
        linhas.append("#" * 60)
        for caminho, conteudo in arquivos:
            linhas.append("")
            linhas.append("=" * 60)
            linhas.append(f"ARQUIVO: {caminho}")
            linhas.append("=" * 60)
            linhas.append(conteudo)

    escrever_secao("SCRIPTS (.gd)", scripts)
    escrever_secao("CENAS (.tscn — estrutura)", cenas)
    escrever_secao("RESOURCES (.tres)", resources)

    total = len(scripts) + len(cenas) + len(resources)
    linhas.append("")
    linhas.append("=" * 60)
    linhas.append(f"TOTAL: {len(scripts)} scripts | {len(cenas)} cenas | {len(resources)} resources")
    linhas.append("=" * 60)

    saida_path = os.path.join(raiz, SAIDA)
    with open(saida_path, "w", encoding="utf-8") as f:
        f.write("\n".join(linhas))

    print(f"\n✅ Exportação concluída!")
    print(f"📄 Arquivo gerado: {saida_path}")
    print(f"📦 Scripts: {len(scripts)} | Cenas: {len(cenas)} | Resources: {len(resources)}")
    print(f"📦 Total: {total} arquivos")


if __name__ == "__main__":
    exportar_projeto()
