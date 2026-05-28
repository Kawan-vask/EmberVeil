import os
import sys

# ============================================================
#  EXPORTAR PROJETO GODOT — EMBERVEIL
#  Coloca esse arquivo na RAIZ do projeto e roda com Python
#
#  USO:
#    python exportar_godot.py           → export completo (análise geral)
#    python exportar_godot.py slim      → sem comentários (~30% menor)
#    python exportar_godot.py modulo    → um arquivo por módulo
#    python exportar_godot.py slim modulo → slim + modular
#
#  ARQUIVOS GERADOS (modo modular):
#    emberveil_core.txt      → Autoloads (GameManager, SignalBus, etc)
#    emberveil_player.txt    → Player + Componentes + Lantern
#    emberveil_enemies.txt   → EnemyBase + EnemyDirector + Nests
#    emberveil_ui.txt        → HUD + PowerUpScreen + ShopScreen + menus
#    emberveil_world.txt     → Cabana + Interactables + Systems
#    emberveil_resources.txt → Scripts de Resource (.gd) + .tres
#    emberveil_scenes.txt    → Estrutura das cenas (.tscn)
# ============================================================

SAIDA_COMPLETA = "emberveil_export.txt"
IGNORAR_PASTAS = {".godot", ".git", "addons", "Assets"}
PASTAS_RESOURCES = {"Resources", "resources"}

# ============================================================
#  MAPA DE MÓDULOS
#  Chave: nome do módulo | Valor: substrings do caminho que pertencem a ele
#  Um arquivo é atribuído ao primeiro módulo cujo caminho bater
# ============================================================
MODULOS = {
    "core": [
        "Scripts/Autoloads",
        "Scripts\\Autoloads",
    ],
    "player": [
        "Scripts/Player",
        "Scripts\\Player",
    ],
    "enemies": [
        "Scripts/Enemies",
        "Scripts\\Enemies",
        "Scripts/Managers/enemy_director",
        "Scripts\\Managers\\enemy_director",
    ],
    "ui": [
        "Scripts/UI",
        "Scripts\\UI",
    ],
    "world": [
        "Scripts/Interactables",
        "Scripts\\Interactables",
        "Scripts/Systems",
        "Scripts\\Systems",
        "Scripts/Managers",
        "Scripts\\Managers",
    ],
    "resources": [
        "Scripts/Resources",
        "Scripts\\Resources",
    ],
}


# ============================================================
#  FILTRAGEM DE TSCN
# ============================================================

def filtrar_tscn(conteudo: str) -> str:
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
            "vendor_data",
            "available_powerups",
            "lantern_id",
            "capacity_bonus",
            "item_type",
        ]):
            linhas_relevantes.append(linha)

    return "\n".join(linhas_relevantes)


# ============================================================
#  MODO SLIM — remove comentários e regiões
# ============================================================

def aplicar_slim(conteudo: str) -> str:
    linhas = []
    for linha in conteudo.splitlines():
        stripped = linha.strip()

        # Remove blocos de separação visual (linhas só de # ou =)
        if stripped and all(c in "#= " for c in stripped) and len(stripped) > 5:
            continue

        # Remove comentários de cabeçalho de bloco (# ===, # ---, # region header)
        if stripped.startswith("# ===") or stripped.startswith("# ---"):
            continue

        # MANTÉM comentários normais de linha (# algo)
        # MANTÉM docstrings (## algo)
        # Isso evita remover código comentado acidentalmente

        # Remove linhas em branco múltiplas (mantém no máximo uma seguida)
        if stripped == "" and linhas and linhas[-1].strip() == "":
            continue

        linhas.append(linha)

    resultado = "\n".join(linhas)
    return resultado


# ============================================================
#  CLASSIFICAÇÃO EM MÓDULOS
# ============================================================

def classificar_modulo(caminho_relativo: str) -> str:
    caminho = caminho_relativo.replace("\\", "/")
    for nome_modulo, prefixos in MODULOS.items():
        for prefixo in prefixos:
            prefixo_norm = prefixo.replace("\\", "/")
            if prefixo_norm in caminho:
                return nome_modulo
    return "world"  # fallback para scripts não classificados


def is_resource_relevante(caminho_relativo: str) -> bool:
    partes = caminho_relativo.replace("\\", "/").split("/")
    return any(p in PASTAS_RESOURCES for p in partes)


# ============================================================
#  COLETA DE ARQUIVOS
# ============================================================

def coletar_arquivos(raiz: str, modo_slim: bool):
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
                if modo_slim:
                    conteudo = aplicar_slim(conteudo)
                modulo = classificar_modulo(caminho_relativo)
                scripts.append((caminho_relativo, conteudo, modulo))

            elif ext == ".tscn":
                cenas.append((caminho_relativo, filtrar_tscn(conteudo)))

            elif ext == ".tres" and is_resource_relevante(caminho_relativo):
                resources.append((caminho_relativo, conteudo))

    return scripts, cenas, resources


# ============================================================
#  ESCRITA DE ARQUIVO
# ============================================================

def bloco_arquivo(caminho: str, conteudo: str) -> str:
    sep = "=" * 60
    return f"\n{sep}\nARQUIVO: {caminho}\n{sep}\n{conteudo}\n"


def escrever_secao(titulo: str, arquivos: list) -> str:
    if not arquivos:
        return ""
    linhas = [
        "",
        "#" * 60,
        f"#  {titulo} ({len(arquivos)} arquivos)",
        "#" * 60,
    ]
    for item in arquivos:
        caminho, conteudo = item[0], item[1]
        linhas.append(bloco_arquivo(caminho, conteudo))
    return "\n".join(linhas)


def cabecalho(titulo: str, modo_slim: bool, modo_modular: bool) -> str:
    flags = []
    if modo_slim:
        flags.append("SLIM")
    if modo_modular:
        flags.append("MODULAR")
    flag_str = " | ".join(flags) if flags else "COMPLETO"
    return (
        f"{'=' * 60}\n"
        f"  EMBERVEIL — EXPORT DO PROJETO [{flag_str}]\n"
        f"{'=' * 60}\n"
    )


# ============================================================
#  EXPORT COMPLETO (arquivo único)
# ============================================================

def exportar_completo(raiz: str, scripts: list, cenas: list, resources: list,
                      modo_slim: bool):
    saida = os.path.join(raiz, SAIDA_COMPLETA)
    conteudo = cabecalho("Export Completo", modo_slim, False)
    conteudo += escrever_secao("SCRIPTS (.gd)", scripts)
    conteudo += escrever_secao("CENAS (.tscn — estrutura)", cenas)
    conteudo += escrever_secao("RESOURCES (.tres)", resources)

    total = len(scripts) + len(cenas) + len(resources)
    conteudo += (
        f"\n{'=' * 60}\n"
        f"TOTAL: {len(scripts)} scripts | {len(cenas)} cenas | {len(resources)} resources\n"
        f"{'=' * 60}\n"
    )

    with open(saida, "w", encoding="utf-8") as f:
        f.write(conteudo)

    tamanho_kb = os.path.getsize(saida) // 1024
    print(f"  📄 {SAIDA_COMPLETA} ({tamanho_kb} KB) — {total} arquivos")
    return saida


# ============================================================
#  EXPORT MODULAR (um arquivo por módulo)
# ============================================================

def exportar_modular(raiz: str, scripts: list, cenas: list, resources: list,
                     modo_slim: bool):
    arquivos_gerados = []

    # Agrupa scripts por módulo
    por_modulo: dict = {m: [] for m in MODULOS}
    por_modulo["resources"] = []

    for caminho, conteudo, modulo in scripts:
        por_modulo[modulo].append((caminho, conteudo))

    # Módulos de código
    for nome_modulo, arquivos in por_modulo.items():
        if not arquivos:
            continue
        nome_arquivo = f"emberveil_{nome_modulo}.txt"
        saida = os.path.join(raiz, nome_arquivo)

        conteudo = cabecalho(f"Módulo: {nome_modulo.upper()}", modo_slim, True)
        conteudo += escrever_secao(f"SCRIPTS — {nome_modulo.upper()}", arquivos)

        # Resources.txt inclui também os .tres
        if nome_modulo == "resources":
            conteudo += escrever_secao("RESOURCES (.tres)", resources)

        with open(saida, "w", encoding="utf-8") as f:
            f.write(conteudo)

        tamanho_kb = os.path.getsize(saida) // 1024
        print(f"  📄 {nome_arquivo} ({tamanho_kb} KB) — {len(arquivos)} scripts")
        arquivos_gerados.append(saida)

    # Cenas em arquivo separado
    if cenas:
        nome_arquivo = "emberveil_scenes.txt"
        saida = os.path.join(raiz, nome_arquivo)
        conteudo = cabecalho("Cenas", modo_slim, True)
        conteudo += escrever_secao("CENAS (.tscn — estrutura)", cenas)

        with open(saida, "w", encoding="utf-8") as f:
            f.write(conteudo)

        tamanho_kb = os.path.getsize(saida) // 1024
        print(f"  📄 {nome_arquivo} ({tamanho_kb} KB) — {len(cenas)} cenas")
        arquivos_gerados.append(saida)

    return arquivos_gerados


# ============================================================
#  RELATÓRIO DE TAMANHO (identifica scripts pesados)
# ============================================================

def imprimir_relatorio(scripts: list, cenas: list, resources: list):
    print("\n  📊 Scripts mais pesados:")
    ordenados = sorted(scripts, key=lambda x: len(x[1]), reverse=True)
    for caminho, conteudo, modulo in ordenados[:5]:
        nome = os.path.basename(caminho)
        linhas = conteudo.count("\n")
        print(f"     {nome:<35} {linhas:>4} linhas  [{modulo}]")

    # Avisa sobre arquivos suspeitos (vazios ou muito pequenos)
    print("\n  ⚠️  Scripts suspeitos (< 5 linhas — podem estar vazios):")
    suspeitos = [s for s in scripts if s[1].count("\n") < 5]
    if suspeitos:
        for caminho, conteudo, modulo in suspeitos:
            nome = os.path.basename(caminho)
            linhas = conteudo.count("\n")
            print(f"     {nome:<35} {linhas:>4} linhas  [{modulo}]  ← verificar")
    else:
        print("     Nenhum.")


# ============================================================
#  MAIN
# ============================================================

def main():
    args = [a.lower() for a in sys.argv[1:]]
    modo_slim    = "slim" in args
    modo_modular = "modulo" in args or "modular" in args

    raiz = os.path.dirname(os.path.abspath(__file__))

    print("\n🌲 EMBERVEIL — Exportando projeto...")
    if modo_slim:
        print("   Modo SLIM ativado (comentários removidos)")
    if modo_modular:
        print("   Modo MODULAR ativado (um arquivo por módulo)")
    print()

    scripts, cenas, resources = coletar_arquivos(raiz, modo_slim)

    if modo_modular:
        exportar_modular(raiz, scripts, cenas, resources, modo_slim)
    else:
        exportar_completo(raiz, scripts, cenas, resources, modo_slim)

    imprimir_relatorio(scripts, cenas, resources)

    total = len(scripts) + len(cenas) + len(resources)
    print(f"\n✅ Concluído! {total} arquivos exportados.")
    print()


if __name__ == "__main__":
    main()
