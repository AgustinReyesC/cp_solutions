#!/bin/zsh

# ╔═══════════════════════════════════════════════════════════════════╗
# ║  ☕  cpbrew — CLI de Programación Competitiva                    ║
# ║  Agustin Alexis Reyes Castillo · coffeeMeitt                    ║
# ║                                                                   ║
# ║  INSTALACIÓN:                                                     ║
# ║    source /ruta/a/cpbrew.zsh  (desde ~/.zshrc)                   ║
# ╚═══════════════════════════════════════════════════════════════════╝

# ─── Paths y config portable ─────────────────────────────────────────────────
typeset -g CPBREW_SCRIPT_PATH="${${(%):-%N}:A}"
typeset -g CPBREW_SCRIPT_DIR="${CPBREW_SCRIPT_PATH:h}"

_CODE="$(command -v code 2>/dev/null)"
_MKDIR="$(command -v mkdir 2>/dev/null)"
_DATE="$(command -v date 2>/dev/null)"
_SED="$(command -v sed 2>/dev/null)"
_CURL="$(command -v curl 2>/dev/null)"
_CP="$(command -v cp 2>/dev/null)"

CPBREW_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.cpbrew}"
CPBREW_ROOT_FILE="$CPBREW_CONFIG_DIR/root"
CPBREW_DEST_FILE="$CPBREW_CONFIG_DIR/destinations.tsv"

CPBREW_ROOT="$CPBREW_SCRIPT_DIR"
CPBREW_STATS="$HOME/.cpbrew_stats"
CPBREW_SANDBOX="$CPBREW_ROOT/.sandbox"

typeset -gA CPBREW_DEST_MAP

# ─── Colores ─────────────────────────────────────────────────────────────────
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
C='\033[0;36m'
M='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
X='\033[0m'

# ─── Helpers ─────────────────────────────────────────────────────────────────
_sep()  { echo "${DIM}  ────────────────────────────────────────────${X}"; }
_ok()   { echo "  ${G}✓${X} $1"; }
_err()  { echo "  ${R}✗${X} $1"; }
_warn() { echo "  ${Y}⚠${X}  $1"; }
_info() { echo "  ${C}→${X} $1"; }
_today()     { $_DATE +%Y-%m-%d; }
_yesterday() { $_DATE -v-1d +%Y-%m-%d; }
_month()     { $_DATE +%Y-%m; }
_open_code() {
    if [[ -n "$_CODE" ]]; then
        "$_CODE" "$@"
    else
        _warn "VS Code CLI ('code') no está instalado en PATH."
    fi
}

_cb_seed_default_destinations() {
    cat > "$CPBREW_DEST_FILE" << 'EOF'
intro	CSES/introductory_problems
sort	CSES/sorting_and_searching
dp	CSES/dynamic_programming
graph	CSES/graph_algorithms
agraph	CSES/advanced_graph_problems
tree	CSES/tree_algorithms
range	CSES/range_queries
math	CSES/mathematics
string	CSES/string_algorithms
count	CSES/counting_problems
bitwise	CSES/bitwise_operations
geo	CSES/geometry
slide	CSES/sliding_window_problems
const	CSES/construction_problems
inter	CSES/interactive_problems
adv	CSES/advanced_techniques
add1	CSES/additional_problems_I
add2	CSES/additional_problems_II
cf	CODEFORCES
icpc	ICPC/regionales
sim	ICPC/simulacros
sandbox	.sandbox
EOF
}

_cb_bootstrap_config() {
    $_MKDIR -p "$CPBREW_CONFIG_DIR"
    if [[ ! -f "$CPBREW_ROOT_FILE" ]]; then
        echo "$CPBREW_SCRIPT_DIR" > "$CPBREW_ROOT_FILE"
    fi
    if [[ ! -f "$CPBREW_DEST_FILE" ]]; then
        _cb_seed_default_destinations
    fi
}

_cb_set_root() {
    local new_root="${1:A}"
    $_MKDIR -p "$new_root"
    echo "$new_root" > "$CPBREW_ROOT_FILE"
    CPBREW_ROOT="$new_root"
    CPBREW_SANDBOX="$CPBREW_ROOT/.sandbox"
}

_cb_load_config() {
    _cb_bootstrap_config
    local loaded_root
    loaded_root="$(cat "$CPBREW_ROOT_FILE" 2>/dev/null)"
    if [[ -n "$loaded_root" ]]; then
        CPBREW_ROOT="${loaded_root:A}"
    else
        CPBREW_ROOT="$CPBREW_SCRIPT_DIR"
    fi
    CPBREW_SANDBOX="$CPBREW_ROOT/.sandbox"

    CPBREW_DEST_MAP=()
    local dest_alias relpath
    while IFS=$'\t' read -r dest_alias relpath; do
        [[ -z "$dest_alias" ]] && continue
        [[ "$dest_alias" == \#* ]] && continue
        CPBREW_DEST_MAP[$dest_alias]="$relpath"
    done < "$CPBREW_DEST_FILE"
}

_cb_save_destinations() {
    : > "$CPBREW_DEST_FILE"
    local k
    for k in "${(@k)CPBREW_DEST_MAP}"; do
        printf "%s\t%s\n" "$k" "${CPBREW_DEST_MAP[$k]}" >> "$CPBREW_DEST_FILE"
    done
}

_cb_resolve_dest() {
    local key="$1"
    if [[ "$key" == "root" ]]; then
        print -r -- ""
        return 0
    fi
    if [[ -n "${CPBREW_DEST_MAP[$key]+x}" ]]; then
        print -r -- "${CPBREW_DEST_MAP[$key]}"
        return 0
    fi
    if [[ "$key" == */* || "$key" == .* ]]; then
        print -r -- "${key#/}"
        return 0
    fi
    return 1
}

# ─── Init stats ──────────────────────────────────────────────────────────────
_cb_init() {
    $_MKDIR -p "$CPBREW_STATS" "$CPBREW_SANDBOX"
    [[ ! -f "$CPBREW_STATS/total" ]]      && echo "0" > "$CPBREW_STATS/total"
    [[ ! -f "$CPBREW_STATS/solo" ]]       && echo "0" > "$CPBREW_STATS/solo"
    [[ ! -f "$CPBREW_STATS/hint" ]]       && echo "0" > "$CPBREW_STATS/hint"
    [[ ! -f "$CPBREW_STATS/streak" ]]     && echo "0" > "$CPBREW_STATS/streak"
    [[ ! -f "$CPBREW_STATS/last_date" ]]  && _today > "$CPBREW_STATS/last_date"
    [[ ! -f "$CPBREW_STATS/log" ]]        && touch "$CPBREW_STATS/log"
    [[ ! -f "$CPBREW_STATS/milestones" ]] && touch "$CPBREW_STATS/milestones"
}

# ─── Milestone checker ───────────────────────────────────────────────────────
_cb_check_milestones() {
    local total=$1
    local milestones=(50 100 200 300 500 750 1000)
    for m in $milestones; do
        if [[ $total -eq $m ]]; then
            if ! grep -q "^$m$" "$CPBREW_STATS/milestones" 2>/dev/null; then
                echo "$m" >> "$CPBREW_STATS/milestones"
                echo ""
                echo "${BOLD}${Y}  ╔══════════════════════════════════════════╗${X}"
                echo "${BOLD}${Y}  ║  🎉  ¡META ALCANZADA: $m problemas!     ║${X}"
                echo "${BOLD}${Y}  ╚══════════════════════════════════════════╝${X}"
                echo ""
            fi
        fi
    done
}

# ─── Template C++ ────────────────────────────────────────────────────────────
_cb_write_template() {
    local file=$1
    local today=$(_today)
    cat > "$file" << CPPTEMPLATE
// ┌─────────────────────────────────────────────┐
// │  Autor:      Agustin Alexis Reyes Castillo  │
// │  CF:         codeforces.com/profile/coffeeMeitt
// │  CSES:       cses.fi/user/318632            │
// ├─────────────────────────────────────────────┤
// │  Problema:                                  │
// │  Plataforma:                                │
// │  Link:                                      │
// │  Dificultad:                                │
// │  Fecha:      $today                         │
// ├─────────────────────────────────────────────┤
// │  Técnica:                                   │
// │  Resultado:                                 │
// ├─────────────────────────────────────────────┤
// │  Idea:                                      │
// │                                             │
// └─────────────────────────────────────────────┘

#pragma GCC optimize("O2")
#include <bits/stdc++.h>
using namespace std;

typedef long long           ll;
typedef unsigned long long  ull;
typedef pair<int,int>       pii;
typedef pair<ll,ll>         pll;
typedef vector<int>         vi;
typedef vector<ll>          vll;

const ll  MOD  = 1e9 + 7;
const ll  LINF = 1e18;
const int INF  = 1e9;
const double PI = acos(-1.0);

#define pb         push_back
#define all(x)     (x).begin(), (x).end()
#define sz(x)      (int)(x).size()
#define rep(i,a,b) for(int i=(a);i<(b);i++)
#define per(i,a,b) for(int i=(b)-1;i>=(a);i--)
#define yes        cout << "YES\n"
#define no         cout << "NO\n"

#ifdef LOCAL
#define dbg(x) cerr << #x << " = " << x << "\n"
#else
#define dbg(x)
#endif

void solve() {

}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    int t = 1;
    // cin >> t;
    while (t--) solve();
    return 0;
}
CPPTEMPLATE
}

# ═══════════════════════════════════════════════════════════════════
# HELP — individual por comando
# ═══════════════════════════════════════════════════════════════════

_cb_help_main() {
    clear
    echo ""
    echo "${BOLD}${C}  ╔══════════════════════════════════════════════╗${X}"
    echo "${BOLD}${C}  ║  ☕  cpbrew · coffeeMeitt · ICPC Training   ║${X}"
    echo "${BOLD}${C}  ╚══════════════════════════════════════════════╝${X}"
    echo ""
    _sep
    echo "  ${BOLD}NAVEGACIÓN${X}"
    _sep
    printf "  ${G}%-32s${X} %s\n" "cpbrew init [ruta]"        "Definir raíz del proyecto"
    printf "  ${G}%-32s${X} %s\n" "cpbrew go <destino>"      "Abrir carpeta en VSCode"
    printf "  ${G}%-32s${X} %s\n" "cpbrew ls"                "Ver todos los destinos"
    printf "  ${G}%-32s${X} %s\n" "cpbrew dest help"         "Gestionar destinos y alias"
    echo ""
    _sep
    echo "  ${BOLD}PROBLEMAS${X}"
    _sep
    printf "  ${G}%-32s${X} %s\n" "cpbrew new <nombre>"      "Crear .cpp con template"
    printf "  ${G}%-32s${X} %s\n" "cpbrew done"              "Guardar solve (normal o retry)"
    printf "  ${G}%-32s${X} %s\n" "cpbrew log"               "Ver historial de problemas"
    echo ""
    _sep
    echo "  ${BOLD}SANDBOX${X} ${DIM}(repetición espaciada)${X}"
    _sep
    printf "  ${G}%-32s${X} %s\n" "cpbrew sb new <nombre>"   "Crear problema en sandbox"
    printf "  ${G}%-32s${X} %s\n" "cpbrew retry <id>"        "Retry directo (alias de sb retry)"
    printf "  ${G}%-32s${X} %s\n" "cpbrew sb ls"             "Ver problemas en sandbox"
    printf "  ${G}%-32s${X} %s\n" "cpbrew sb retry <nombre>" "Nuevo intento"
    printf "  ${G}%-32s${X} %s\n" "cpbrew sb diff <nombre>"  "Comparar intentos en VSCode"
    printf "  ${G}%-32s${X} %s\n" "cpbrew sb watch"          "Detectar archivos de CPH"
    echo ""
    _sep
    echo "  ${BOLD}IMPORT${X}"
    _sep
    printf "  ${G}%-32s${X} %s\n" "cpbrew import <url|ruta>" "Importar solución + diff"
    echo ""
    _sep
    echo "  ${BOLD}STATS${X}"
    _sep
    printf "  ${G}%-32s${X} %s\n" "cpbrew stats"             "Ver progreso y barras"
    printf "  ${G}%-32s${X} %s\n" "cpbrew streak"            "Ver racha actual"
    echo ""
    _sep
    echo "  ${BOLD}UTILS${X}"
    _sep
    printf "  ${G}%-32s${X} %s\n" "cpbrew stop"              "Alias de cpbrew sb stop"
    printf "  ${G}%-32s${X} %s\n" "cpbrew repo <url>"        "Conectar o actualizar remote origin"
    printf "  ${G}%-32s${X} %s\n" "cpbrew git"               "add + commit + push (elige branch)"
    printf "  ${G}%-32s${X} %s\n" "cpbrew help"              "Mostrar esta ayuda"
    echo ""
    echo "  ${DIM}Tip: cada comando tiene help propio → ${C}cpbrew <cmd> help${X}"
    echo ""
}

_cb_help_go() {
    echo ""
    echo "${BOLD}${C}  cpbrew go${X} — Navegar a una carpeta y abrirla en VSCode"
    _sep
    echo "  ${BOLD}Uso:${X}     ${G}cpbrew go <destino>${X}"
    echo "  ${BOLD}Ejemplo:${X} ${G}cpbrew go math${X}"
    echo "  Usa ${C}cpbrew ls${X} para ver alias y rutas activas."
    echo ""
}

_cb_help_init() {
    echo ""
    echo "${BOLD}${C}  cpbrew init${X} — Definir raíz del proyecto"
    _sep
    echo "  ${BOLD}Uso:${X}     ${G}cpbrew init${X} ${DIM}(usa carpeta actual)${X}"
    echo "  ${BOLD}Uso:${X}     ${G}cpbrew init <ruta>${X}"
    echo ""
    echo "  Guarda la raíz en ${DIM}$CPBREW_ROOT_FILE${X}"
    echo "  y desde ahí se calculan sandbox/destinos."
    echo ""
}

_cb_help_dest() {
    echo ""
    echo "${BOLD}${C}  cpbrew dest${X} — Gestionar destinos dinámicos"
    _sep
    printf "  ${G}%-42s${X} %s\n" "cpbrew dest add" "Crear carpeta destino (interactivo)"
    printf "  ${G}%-42s${X} %s\n" "cpbrew dest add <alias> <ruta_relativa>" "Crear/registrar sin preguntas"
    printf "  ${G}%-42s${X} %s\n" "cpbrew dest alias add <alias> <destino>" "Crear alias para destino existente"
    printf "  ${G}%-42s${X} %s\n" "cpbrew dest alias rm <alias>" "Eliminar solo alias"
    printf "  ${G}%-42s${X} %s\n" "cpbrew dest rm [alias]" "Eliminar alias (y opcional carpeta)"
    echo ""
}

_cb_help_new() {
    echo ""
    echo "${BOLD}${C}  cpbrew new${X} — Crear/abrir problema nuevo en sandbox"
    _sep
    echo "  ${BOLD}Uso:${X}     ${G}cpbrew new <nombre>${X}"
    echo "  ${BOLD}Ejemplo:${X} ${G}cpbrew new 1900A${X}"
    echo ""
    echo "  Crea .sandbox/<nombre>.cpp y lo abre."
    echo "  Este es el flujo recomendado para problemas nuevos."
    echo ""
    echo "  ${DIM}Tip: navega primero con ${C}cpbrew go <destino>${DIM} para crear en la carpeta correcta.${X}"
    echo ""
}

_cb_help_sb() {
    echo ""
    echo "${BOLD}${C}  cpbrew sb${X} — Sandbox de repetición espaciada"
    _sep
    printf "  ${G}%-28s${X} %s\n" "cpbrew sb new <id>"       "Crear/abrir problema en sandbox"
    printf "  ${G}%-28s${X} %s\n" "cpbrew sb retry <id>"     "Resetear código (mantiene test_cases)"
    printf "  ${G}%-28s${X} %s\n" "cpbrew sb diff <id>"      "Diff entre dos snapshots de retries"
    printf "  ${G}%-28s${X} %s\n" "cpbrew sb ls"             "Listar todos los problemas"
    printf "  ${G}%-28s${X} %s\n" "cpbrew sb start"          "Iniciar watch en background"
    printf "  ${G}%-28s${X} %s\n" "cpbrew sb stop"           "Detener watch"
    printf "  ${G}%-28s${X} %s\n" "cpbrew sb status"         "Ver si watch está corriendo"
    echo ""
    echo "  ${BOLD}Cómo funciona:${X}"
    echo "  Cada problema vive en:"
    echo "  ${DIM}.sandbox/<id>.cpp${X}                    ${DIM}← archivo de trabajo${X}"
    echo "  ${DIM}.sandbox/.cpbrew/<id>/retries/*.cpp${X} ${DIM}← snapshots para diff${X}"
    echo "  ${DIM}.sandbox/.cpbrew/<id>/meta.txt${X}"
    echo ""
    echo "  ${BOLD}Integración CPH:${X}"
    echo "  ${G}cpbrew sb watch${X} monitorea la carpeta activa."
    echo "  Cuando CPH crea un .cpp, se copia a .sandbox/<id>.cpp"
    echo "  y los test_cases del mismo nombre se copian al sandbox."
    echo ""
    echo "  ${DIM}Tip: al hacer ${C}cpbrew done${DIM}, se guarda snapshot automático en retries.${X}"
    echo ""
}

_cb_help_git() {
    echo ""
    echo "${BOLD}${C}  cpbrew git${X} — Push rápido al repo"
    _sep
    echo "  ${BOLD}Uso:${X} ${G}cpbrew git${X}"
    echo ""
    echo "  Lista las branches disponibles y te deja elegir."
    echo "  Luego hace: git add . → git commit → git push"
    echo ""
    echo "  ${DIM}Tip: Enter en el mensaje usa fecha automática como commit.${X}"
    echo "  ${DIM}Tip: Enter en la branch mantiene la actual.${X}"
    echo ""
}

_cb_help_repo() {
    echo ""
    echo "${BOLD}${C}  cpbrew repo${X} — Conectar repo remoto"
    _sep
    echo "  ${BOLD}Uso:${X} ${G}cpbrew repo <url>${X}"
    echo ""
    echo "  Si no existe .git, inicializa repo local."
    echo "  Luego agrega o actualiza ${BOLD}origin${X} con la URL."
    echo ""
}

_cb_help_import() {
    echo ""
    echo "${BOLD}${C}  cpbrew import${X} — Importar solución desde URL o ruta local"
    _sep
    echo "  ${BOLD}Uso:${X}"
    printf "  ${G}%-48s${X} %s\n" "cpbrew import <url>"  "Desde GitHub (raw o normal)"
    printf "  ${G}%-48s${X} %s\n" "cpbrew import <ruta>" "Desde archivo local"
    echo ""
    echo "  ${BOLD}Ejemplos:${X}"
    echo "  ${G}cpbrew import https://github.com/user/repo/blob/main/sol.cpp${X}"
    echo "  ${G}cpbrew import ~/Downloads/solution.cpp${X}"
    echo ""
    echo "  Después de importar, ofrece hacer diff con otro archivo."
    echo "  ${DIM}Tip: links normales de GitHub se convierten a raw automáticamente.${X}"
    echo ""
}

_cb_help_stats() {
    echo ""
    echo "${BOLD}${C}  cpbrew stats${X} — Ver progreso"
    _sep
    echo "  Muestra barras de progreso hacia:"
    echo "  · ${BOLD}1000 problemas${X} totales"
    echo "  · ${BOLD}150 problemas${X} este mes"
    echo ""
    echo "  También muestra ratio solo/hint, sandbox y racha."
    echo ""
    echo "  ${BOLD}Metas automáticas:${X} 50, 100, 200, 300, 500, 750, 1000"
    echo "  Al llegar a cada una se celebra con un mensaje especial."
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
# GO
# ═══════════════════════════════════════════════════════════════════

_cb_go() {
    [[ "$1" == "help" ]] && _cb_help_go && return
    local dest=$1
    if [[ -z "$dest" ]]; then
        _err "Especifica un destino. Usa ${C}cpbrew go help${X}."
        return 1
    fi
    local target_path
    target_path="$(_cb_resolve_dest "$dest")"
    if [[ $? -ne 0 ]]; then
        _err "Destino '${dest}' no encontrado. Usa ${C}cpbrew ls${X}."
        return 1
    fi
    local fullpath="$CPBREW_ROOT"
    [[ -n "$target_path" ]] && fullpath="$CPBREW_ROOT/$target_path"
    $_MKDIR -p "$fullpath"
    cd "$fullpath"
    _ok "${BOLD}$fullpath${X}"
    _open_code .
}

# ═══════════════════════════════════════════════════════════════════
# LS
# ═══════════════════════════════════════════════════════════════════

_cb_ls() {
    echo ""
    echo "${BOLD}${C}  ☕  Destinos disponibles${X}"
    echo "  ${DIM}Root: $CPBREW_ROOT${X}"
    echo ""
    printf "  ${Y}%-14s${X} ${DIM}%s${X}\n" "root" "raíz del repo"
    local alias_key
    for alias_key in "${(@k)CPBREW_DEST_MAP}"; do
        printf "  ${Y}%-14s${X} ${DIM}%s${X}\n" "$alias_key" "${CPBREW_DEST_MAP[$alias_key]}"
    done
    echo ""
}

_cb_choose_parent_alias() {
    local -a aliases
    aliases=("root")
    local a
    for a in "${(@k)CPBREW_DEST_MAP}"; do
        aliases+=("$a")
    done
    echo "" >&2
    echo "  ${BOLD}Selecciona carpeta padre:${X}" >&2
    local i=1
    for a in $aliases; do
        local rel="$(_cb_resolve_dest "$a")"
        [[ -z "$rel" ]] && rel="."
        printf "  ${Y}%2d)${X} %-14s ${DIM}%s${X}\n" $i "$a" "$rel" >&2
        i=$((i+1))
    done
    echo -n "  Número: " >&2
    local pick
    read pick
    if [[ ! "$pick" =~ ^[0-9]+$ ]] || (( pick < 1 || pick > ${#aliases[@]} )); then
        _err "Selección inválida."
        return 1
    fi
    REPLY="${aliases[$pick]}"
}

_cb_dest_add() {
    local alias="$1"
    local relpath="$2"

    if [[ -z "$alias" ]]; then
        echo -n "  Alias nuevo: "
        read alias
        [[ -z "$alias" ]] && _err "Alias vacío." && return 1
    fi
    if [[ "$alias" == "root" ]]; then
        _err "El alias 'root' está reservado."
        return 1
    fi

    if [[ -z "$relpath" ]]; then
        _cb_choose_parent_alias || return 1
        local parent_alias="$REPLY"
        local parent_rel="$(_cb_resolve_dest "$parent_alias")"
        echo -n "  Nombre de carpeta a crear: "
        local folder
        read folder
        [[ -z "$folder" ]] && _err "Nombre vacío." && return 1
        relpath="$folder"
        [[ -n "$parent_rel" ]] && relpath="$parent_rel/$folder"
    fi

    relpath="${relpath#/}"
    CPBREW_DEST_MAP[$alias]="$relpath"
    _cb_save_destinations
    $_MKDIR -p "$CPBREW_ROOT/$relpath"
    _ok "Destino '${BOLD}$alias${X}' → ${DIM}$relpath${X}"
}

_cb_dest_alias_add() {
    local new_alias="$1"
    local target="$2"
    if [[ -z "$new_alias" || -z "$target" ]]; then
        _err "Uso: cpbrew dest alias add <alias> <destino>"
        return 1
    fi
    [[ "$new_alias" == "root" ]] && _err "El alias 'root' está reservado." && return 1
    local relpath
    relpath="$(_cb_resolve_dest "$target")"
    if [[ $? -ne 0 ]]; then
        _err "Destino '${target}' no existe."
        return 1
    fi
    CPBREW_DEST_MAP[$new_alias]="$relpath"
    _cb_save_destinations
    _ok "Alias '${BOLD}$new_alias${X}' agregado para ${DIM}$relpath${X}"
}

_cb_dest_alias_rm() {
    local alias="$1"
    if [[ -z "$alias" ]]; then
        _err "Uso: cpbrew dest alias rm <alias>"
        return 1
    fi
    if [[ -z "${CPBREW_DEST_MAP[$alias]+x}" ]]; then
        _err "Alias '${alias}' no existe."
        return 1
    fi
    unset "CPBREW_DEST_MAP[$alias]"
    _cb_save_destinations
    _ok "Alias '${BOLD}$alias${X}' eliminado."
}

_cb_dest_rm() {
    local alias="$1"
    if [[ -z "$alias" ]]; then
        echo ""
        echo "  ${BOLD}Alias disponibles:${X}"
        local a
        for a in "${(@k)CPBREW_DEST_MAP}"; do
            printf "  ${Y}%-14s${X} ${DIM}%s${X}\n" "$a" "${CPBREW_DEST_MAP[$a]}"
        done
        echo -n "  Alias a eliminar: "
        read alias
    fi
    if [[ -z "${CPBREW_DEST_MAP[$alias]+x}" ]]; then
        _err "Alias '${alias}' no existe."
        return 1
    fi
    local relpath="${CPBREW_DEST_MAP[$alias]}"
    unset "CPBREW_DEST_MAP[$alias]"
    _cb_save_destinations
    _ok "Alias '${BOLD}$alias${X}' eliminado."

    local k refs=0
    for k in "${(@k)CPBREW_DEST_MAP}"; do
        [[ "${CPBREW_DEST_MAP[$k]}" == "$relpath" ]] && refs=$((refs+1))
    done
    if (( refs > 0 )); then
        _warn "La ruta '${relpath}' sigue usada por otros aliases. No se elimina carpeta."
        return 0
    fi

    echo -n "  ¿Eliminar también carpeta física '${relpath}'? [y/N]: "
    local ans
    read ans
    if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
        local full="$CPBREW_ROOT/$relpath"
        if [[ -n "$relpath" && -d "$full" ]]; then
            rm -rf "$full"
            _ok "Carpeta eliminada: ${DIM}$full${X}"
        fi
    fi
}

_cb_dest() {
    local sub="$1"
    shift
    case "$sub" in
        add|"") _cb_dest_add "$@" ;;
        rm|remove|del|delete) _cb_dest_rm "$@" ;;
        alias)
            local action="$1"
            shift
            case "$action" in
                add) _cb_dest_alias_add "$@" ;;
                rm|remove|del|delete) _cb_dest_alias_rm "$@" ;;
                *) _err "Uso: cpbrew dest alias [add|rm] ..." ;;
            esac
            ;;
        help) _cb_help_dest ;;
        *) _err "Subcomando dest inválido. Usa ${C}cpbrew dest help${X}." ;;
    esac
}

_cb_init_root() {
    [[ "$1" == "help" ]] && _cb_help_init && return
    local target="${1:-$PWD}"
    _cb_set_root "$target"
    _cb_init
    _ok "Raíz configurada en ${BOLD}$CPBREW_ROOT${X}"
    _info "Config: ${DIM}$CPBREW_CONFIG_DIR${X}"
}

_cb_problem_dir() {
    print -r -- "$CPBREW_SANDBOX/.cpbrew/$1"
}

_cb_problem_file() {
    print -r -- "$CPBREW_SANDBOX/$1.cpp"
}

_cb_problem_retries_dir() {
    print -r -- "$(_cb_problem_dir "$1")/retries"
}

_cb_problem_id_from_input() {
    local raw="$1"
    local base="$(basename "$raw")"
    base="${base%.cpp}"
    print -r -- "$base"
}

_cb_meta_get() {
    local dir="$1"
    local key="$2"
    grep "^${key}=" "$dir/meta.txt" 2>/dev/null | head -1 | cut -d= -f2-
}

_cb_meta_set() {
    local dir="$1"
    local key="$2"
    local value="$3"
    if grep -q "^${key}=" "$dir/meta.txt" 2>/dev/null; then
        $_SED -i '' "s|^${key}=.*|${key}=${value}|" "$dir/meta.txt"
    else
        printf "%s=%s\n" "$key" "$value" >> "$dir/meta.txt"
    fi
}

_cb_set_current_problem() {
    echo "$1" > "$CPBREW_STATS/current_problem"
}

_cb_get_current_problem() {
    cat "$CPBREW_STATS/current_problem" 2>/dev/null
}

_cb_problem_bootstrap_meta() {
    local id="$1"
    local dir="$(_cb_problem_dir "$id")"
    $_MKDIR -p "$dir" "$(_cb_problem_retries_dir "$id")"
    if [[ ! -f "$dir/meta.txt" ]]; then
        printf "problema=%s\ncreado=%s\nid=%s\nretries=0\nretry_active=0\n" \
            "$id" "$(_today)" "$id" > "$dir/meta.txt"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# NEW
# ═══════════════════════════════════════════════════════════════════

_cb_new() {
    [[ "$1" == "help" ]] && _cb_help_new && return
    local name=$1
    if [[ -z "$name" ]]; then
        _err "Especifica un nombre. Usa ${C}cpbrew new <id>${X}."
        return 1
    fi
    _cb_sandbox new "$name"
}

# ═══════════════════════════════════════════════════════════════════
# SANDBOX
# ═══════════════════════════════════════════════════════════════════

_cb_sandbox() {
    local subcmd=$1
    [[ "$subcmd" == "help" || -z "$subcmd" ]] && _cb_help_sb && return
    shift

    case $subcmd in
        new)
            local id=$1
            if [[ -z "$id" ]]; then
                _err "Especifica un ID. Ej: ${C}cpbrew sb new counting_divisors${X}"
                return 1
            fi
            local dir="$(_cb_problem_dir "$id")"
            local file="$(_cb_problem_file "$id")"
            _cb_problem_bootstrap_meta "$id"
            _cb_meta_set "$dir" "retry_active" "0"
            [[ ! -f "$file" ]] && _cb_write_template "$file"
            _cb_set_current_problem "$id"
            echo ""
            _ok "${BOLD}Sandbox activo:${X} $id"
            echo "  ${DIM}Archivo de trabajo: $file${X}"
            echo ""
            _open_code "$file"
            ;;

        retry)
            local id=$1
            [[ -z "$id" ]] && id="$(_cb_get_current_problem)"
            if [[ -z "$id" ]]; then
                _err "Especifica ID. Ej: ${C}cpbrew sb retry counting_divisors${X}"
                return 1
            fi
            local dir="$(_cb_problem_dir "$id")"
            local file="$(_cb_problem_file "$id")"
            if [[ ! -f "$file" ]]; then
                _err "'$id' no encontrado en sandbox (.sandbox/$id.cpp)."
                return 1
            fi
            _cb_problem_bootstrap_meta "$id"
            local retries_dir="$(_cb_problem_retries_dir "$id")"
            if [[ -s "$file" ]]; then
                local pre="$retries_dir/pre_retry_$($_DATE +%Y%m%d_%H%M%S).cpp"
                $_CP "$file" "$pre"
            fi
            : > "$file"
            local retries="$(_cb_meta_get "$dir" "retries")"
            [[ -z "$retries" ]] && retries=0
            retries=$((retries + 1))
            _cb_meta_set "$dir" "retries" "$retries"
            _cb_meta_set "$dir" "retry_active" "1"
            _cb_set_current_problem "$id"
            echo ""
            _ok "${BOLD}$id${X} listo para retry #${retries}"
            echo "  ${DIM}Código reiniciado en: $file${X}"
            echo "  ${DIM}Test cases se mantienen en sandbox.${X}"
            echo ""
            _open_code "$file"
            ;;

        diff)
            local id=$1
            [[ -z "$id" ]] && id="$(_cb_get_current_problem)"
            if [[ -z "$id" ]]; then
                _err "Especifica ID. Ej: ${C}cpbrew sb diff counting_divisors${X}"
                return 1
            fi
            local dir="$(_cb_problem_dir "$id")"
            local retries_dir="$(_cb_problem_retries_dir "$id")"
            local -a files=("$retries_dir"/*.cpp(N))
            if (( ${#files[@]} < 2 )); then
                _warn "Necesitas al menos 2 snapshots en $retries_dir."
                return 1
            fi
            echo ""
            echo "  ${BOLD}Snapshots de $id:${X}"
            local i=1
            local f
            for f in $files; do
                printf "  ${Y}%2d)${X} %s\n" $i "$(basename "$f")"
                i=$((i+1))
            done
            echo -n "  Índice A: "
            local ia
            read ia
            echo -n "  Índice B: "
            local ib
            read ib
            if [[ ! "$ia" =~ ^[0-9]+$ || ! "$ib" =~ ^[0-9]+$ ]]; then
                _err "Índices inválidos."
                return 1
            fi
            if (( ia < 1 || ia > ${#files[@]} || ib < 1 || ib > ${#files[@]} )); then
                _err "Índices fuera de rango."
                return 1
            fi
            local a="${files[$ia]}"
            local b="${files[$ib]}"
            echo ""
            _info "Abriendo diff..."
            echo "  ${DIM}A: $(basename "$a")${X}"
            echo "  ${DIM}B: $(basename "$b")${X}"
            echo ""
            _open_code --diff "$a" "$b"
            ;;

        ls)
            echo ""
            echo "${BOLD}${C}  ☕  Sandbox — problemas${X}"
            _sep
            local -a cpps=("$CPBREW_SANDBOX"/*.cpp(N))
            if (( ${#cpps[@]} == 0 )); then
                echo "  ${DIM}Vacío. Usa ${C}cpbrew sb new <nombre>${DIM} para agregar.${X}"
            else
                printf "  ${BOLD}%-28s  %-8s  %-8s  %-12s${X}\n" "Problema" "Retries" "Snaps" "Creado"
                _sep
                local file
                for file in $cpps; do
                    local id="$(basename "$file" .cpp)"
                    local dir="$(_cb_problem_dir "$id")"
                    local retries_dir="$(_cb_problem_retries_dir "$id")"
                    local retries=$(_cb_meta_get "$dir" "retries")
                    [[ -z "$retries" ]] && retries=0
                    local -a snap_files=("$retries_dir"/*.cpp(N))
                    local snaps=${#snap_files[@]}
                    local created=$(_cb_meta_get "$dir" "creado")
                    [[ -z "$created" ]] && created="-"
                    printf "  ${Y}%-28s${X}  ${G}%-8s${X}  ${C}%-8s${X}  ${DIM}%s${X}\n" "$id" "$retries" "$snaps" "$created"
                done
                _sep
            fi
            echo ""
            ;;

        start|watch)
            local watch_dir=$(pwd)
            local pidfile="$CPBREW_STATS/watch.pid"
            local logfile="$CPBREW_STATS/watch.log"

            if [[ -f "$pidfile" ]]; then
                local old_pid=$(cat "$pidfile")
                if kill -0 "$old_pid" 2>/dev/null; then
                    _warn "watch ya está corriendo ${DIM}(PID $old_pid)${X}. Usa ${C}cpbrew sb stop${X} primero."
                    return 1
                fi
            fi

            # Script de watch que corre en background
            {
                local -a known_files=("$watch_dir"/*.cpp(N))
                echo "[$(date '+%H:%M:%S')] Watch iniciado en: $watch_dir" >> "$logfile"
                while true; do
                    sleep 2
                    local -a current_files=("$watch_dir"/*.cpp(N))
                    for f in $current_files; do
                        local found=0
                        for k in $known_files; do
                            [[ "$f" == "$k" ]] && found=1 && break
                        done
                        if [[ $found -eq 0 ]]; then
                            local fname=$(basename "$f" .cpp)
                            local dir="$(_cb_problem_dir "$fname")"
                            local target="$(_cb_problem_file "$fname")"
                            _cb_problem_bootstrap_meta "$fname"
                            _cb_meta_set "$dir" "retry_active" "0"
                            $_CP "$f" "$target"
                            for extra in "$watch_dir"/"$fname".*; do
                                [[ -f "$extra" ]] || continue
                                [[ "$extra" == "$f" ]] && continue
                                $_CP "$extra" "$CPBREW_SANDBOX/"
                            done
                            _cb_set_current_problem "$fname"
                            echo "[$(date '+%H:%M:%S')] CPH: $fname → .sandbox/$fname.cpp" >> "$logfile"
                            known_files=("${current_files[@]}")
                        fi
                    done
                done
            } &

            local pid=$!
            echo $pid > "$pidfile"
            # Matar el proceso cuando se cierre la terminal
            disown $pid

            echo ""
            _ok "Watch iniciado en background ${DIM}(PID $pid)${X}"
            echo "  ${DIM}Carpeta: $watch_dir${X}"
            echo "  ${DIM}Log:     $logfile${X}"
            echo "  ${DIM}Nuevos problemas se copian a .sandbox/<id>.cpp${X}"
            echo "  ${DIM}Usa ${C}cpbrew sb stop${X}${DIM} para detenerlo.${X}"
            echo ""
            ;;

        stop)
            local pidfile="$CPBREW_STATS/watch.pid"
            if [[ ! -f "$pidfile" ]]; then
                _warn "No hay watch corriendo."
                return 1
            fi
            local pid=$(cat "$pidfile")
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid"
                rm -f "$pidfile"
                echo ""
                _ok "Watch detenido ${DIM}(PID $pid)${X}"
                echo ""
            else
                rm -f "$pidfile"
                _warn "El proceso ya no existía. PID file limpiado."
            fi
            ;;

        status)
            local pidfile="$CPBREW_STATS/watch.pid"
            local logfile="$CPBREW_STATS/watch.log"
            echo ""
            if [[ -f "$pidfile" ]] && kill -0 "$(cat $pidfile)" 2>/dev/null; then
                local pid=$(cat "$pidfile")
                _ok "Watch corriendo ${DIM}(PID $pid)${X}"
                echo ""
                echo "  ${BOLD}Últimas 5 detecciones:${X}"
                tail -5 "$logfile" 2>/dev/null | while IFS= read -r line; do
                    echo "  ${DIM}$line${X}"
                done
            else
                _warn "Watch no está corriendo."
            fi
            echo ""
            ;;

        *) _err "Subcomando desconocido. Usa ${C}cpbrew sb help${X}." ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# IMPORT
# ═══════════════════════════════════════════════════════════════════

_cb_import() {
    [[ "$1" == "help" ]] && _cb_help_import && return
    local src=$1
    if [[ -z "$src" ]]; then
        _err "Especifica una URL o ruta. Usa ${C}cpbrew import help${X}."
        return 1
    fi
    echo -n "  Nombre para guardar (sin .cpp): "
    read fname
    [[ -z "$fname" ]] && _err "Nombre vacío." && return 1
    local dest="${fname}.cpp"
    if [[ "$src" == http* ]]; then
        if [[ "$src" == *"github.com"* && "$src" != *"raw.githubusercontent"* ]]; then
            src=$(echo "$src" | $_SED 's|github.com|raw.githubusercontent.com|' | $_SED 's|/blob/|/|')
        fi
        _info "Descargando..."
        $_CURL -s "$src" -o "$dest"
        [[ $? -ne 0 ]] && _err "No se pudo descargar." && return 1
    else
        [[ ! -f "$src" ]] && _err "Archivo no encontrado: $src" && return 1
        $_CP "$src" "$dest"
    fi
    _ok "Importado como ${BOLD}$dest${X}"
    echo -n "  ¿Comparar con otro archivo? (ruta o Enter para omitir): "
    read cmp
    if [[ -n "$cmp" && -f "$cmp" ]]; then
        _open_code --diff "$cmp" "$dest"
    else
        _open_code "$dest"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# DONE
# ═══════════════════════════════════════════════════════════════════

_cb_done() {
    local arg_problem="$1"
    local arg_dest="$2"
    local arg_save="$3"
    _cb_init
    echo ""
    echo "${BOLD}${C}  ☕  Registrar done (desde sandbox)${X}"
    _sep
    local current="$(_cb_get_current_problem)"
    local prob_name
    if [[ -n "$arg_problem" ]]; then
        prob_name="$(_cb_problem_id_from_input "$arg_problem")"
        echo "  ID problema: ${BOLD}$prob_name${X} ${DIM}(desde argumento)${X}"
    else
        echo -n "  ID problema (Enter = $current): "
        read prob_name
        [[ -z "$prob_name" ]] && prob_name="$current"
    fi
    if [[ -z "$prob_name" ]]; then
        _err "No hay problema actual. Usa ${C}cpbrew sb new <id>${X} o ${C}cpbrew sb watch${X}."
        return 1
    fi
    local sb_dir="$(_cb_problem_dir "$prob_name")"
    local sb_file="$(_cb_problem_file "$prob_name")"
    if [[ ! -f "$sb_file" ]]; then
        _err "No existe archivo de sandbox: $sb_file"
        return 1
    fi
    _cb_problem_bootstrap_meta "$prob_name"
    local retries_dir="$(_cb_problem_retries_dir "$prob_name")"

    local is_retry="$(_cb_meta_get "$sb_dir" "retry_active")"
    [[ -z "$is_retry" ]] && is_retry=0
    local dest_key="retry_log"
    local save_name="$prob_name"
    local final_file=""
    local snap=""
    local snap_base="$prob_name"

    if [[ "$is_retry" != "1" ]]; then
        if [[ -n "$arg_dest" ]]; then
            dest_key="$arg_dest"
            echo "  Carpeta destino: ${BOLD}$dest_key${X} ${DIM}(desde argumento)${X}"
        else
            echo -n "  Carpeta destino (alias o ruta, Enter = root): "
            read dest_key
            [[ -z "$dest_key" ]] && dest_key="root"
        fi
        local relpath
        relpath="$(_cb_resolve_dest "$dest_key")"
        if [[ $? -ne 0 ]]; then
            _err "Destino '${dest_key}' no válido. Usa ${C}cpbrew ls${X}."
            return 1
        fi
        local dest_dir="$CPBREW_ROOT"
        [[ -n "$relpath" ]] && dest_dir="$CPBREW_ROOT/$relpath"
        $_MKDIR -p "$dest_dir"

        if [[ -n "$arg_save" ]]; then
            save_name="$arg_save"
            echo "  Nombre guardado: ${BOLD}$save_name${X} ${DIM}(desde argumento)${X}"
        elif [[ -n "$arg_problem" ]]; then
            save_name="$prob_name"
            echo "  Nombre guardado: ${BOLD}$save_name${X} ${DIM}(automático por archivo)${X}"
        else
            echo -n "  Nombre para guardar (sin .cpp, Enter = $prob_name): "
            read save_name
            [[ -z "$save_name" ]] && save_name="$prob_name"
        fi
        final_file="$dest_dir/${save_name}.cpp"
        $_CP "$sb_file" "$final_file"
        snap_base="$save_name"
    else
        echo "  ${Y}↺${X} Modo retry: no se copia a carpeta original."
        echo "  ${DIM}Se guardará solo en historial de retries.${X}"
    fi

    $_MKDIR -p "$retries_dir"
    if [[ "$is_retry" == "1" ]]; then
        snap="$retries_dir/retry_done_$($_DATE +%Y%m%d_%H%M%S)_${snap_base}.cpp"
    else
        snap="$retries_dir/done_$($_DATE +%Y%m%d_%H%M%S)_${snap_base}.cpp"
    fi
    $_CP "$sb_file" "$snap"

    echo ""
    echo "  ${G}1${X}) Solo ${DIM}(hard)${X}"
    echo "  ${Y}2${X}) Con 1 hint ${DIM}(easy)${X}"
    echo "  ${R}3${X}) Con 2+ hints"
    echo -n "  Resultado: "
    read ropt
    local rstr
    case $ropt in
        1) rstr="solo" ;;
        2) rstr="1 hint" ;;
        3) rstr="2+ hints" ;;
        *) rstr="desconocido" ;;
    esac
    local total=$(cat "$CPBREW_STATS/total")
    local new_total=$((total + 1))
    echo $new_total > "$CPBREW_STATS/total"
    if [[ $ropt == 1 ]]; then
        local s=$(cat "$CPBREW_STATS/solo"); echo $((s+1)) > "$CPBREW_STATS/solo"
    else
        local h=$(cat "$CPBREW_STATS/hint"); echo $((h+1)) > "$CPBREW_STATS/hint"
    fi
    local last=$(cat "$CPBREW_STATS/last_date")
    local today=$(_today)
    local yesterday=$(_yesterday)
    local streak=$(cat "$CPBREW_STATS/streak")
    if [[ "$last" == "$today" ]]; then
        :
    elif [[ "$last" == "$yesterday" ]]; then
        streak=$((streak+1)); echo $streak > "$CPBREW_STATS/streak"
    else
        streak=1; echo 1 > "$CPBREW_STATS/streak"
    fi
    echo "$today" > "$CPBREW_STATS/last_date"
    if [[ "$is_retry" == "1" ]]; then
        echo "$today | $prob_name | RETRY | $rstr | $(basename "$snap")" >> "$CPBREW_STATS/log"
    else
        echo "$today | $prob_name | NORMAL | $rstr | $dest_key/$save_name.cpp" >> "$CPBREW_STATS/log"
    fi
    echo ""
    _sep
    _ok "${BOLD}$prob_name${X} registrado ${DIM}($rstr)${X}"
    if [[ "$is_retry" == "1" ]]; then
        echo "  Guardado como retry en log: ${DIM}$snap${X}"
    else
        echo "  Guardado en: ${BOLD}$final_file${X}"
        echo "  Snapshot retry: ${DIM}$snap${X}"
    fi
    echo "  Total: ${BOLD}$new_total${X}  ·  Racha: ${M}${BOLD}${streak} días 🔥${X}"
    _sep
    echo ""
    _cb_meta_set "$sb_dir" "retry_active" "0"
    _cb_set_current_problem "$prob_name"
    _cb_check_milestones $new_total
}

# ═══════════════════════════════════════════════════════════════════
# STATS
# ═══════════════════════════════════════════════════════════════════

_cb_stats() {
    [[ "$1" == "help" ]] && _cb_help_stats && return
    _cb_init
    local total=$(cat "$CPBREW_STATS/total")
    local solo=$(cat "$CPBREW_STATS/solo")
    local hint=$(cat "$CPBREW_STATS/hint")
    local streak=$(cat "$CPBREW_STATS/streak")
    local solo_pct=0
    [[ $total -gt 0 ]] && solo_pct=$((solo*100/total))
    local f=$((total*30/1000)); [[ $f -gt 30 ]] && f=30
    local e=$((30-f))
    local bar="${G}"; for i in $(seq 1 $f); do bar+="█"; done
    bar+="${DIM}"; for i in $(seq 1 $e); do bar+="░"; done; bar+="${X}"
    local month=$(_month)
    local mc=$(grep "^$month" "$CPBREW_STATS/log" 2>/dev/null | wc -l | tr -d ' ')
    local mf=$((mc*20/150)); [[ $mf -gt 20 ]] && mf=20
    local me=$((20-mf))
    local mbar="${C}"; for i in $(seq 1 $mf); do mbar+="█"; done
    mbar+="${DIM}"; for i in $(seq 1 $me); do mbar+="░"; done; mbar+="${X}"
    local -a sb_files=("$CPBREW_SANDBOX"/*.cpp(N))
    local sb=${#sb_files[@]}
    echo ""
    echo "${BOLD}${C}  ╔══════════════════════════════════════════════╗${X}"
    echo "${BOLD}${C}  ║  ☕  cpbrew stats · coffeeMeitt             ║${X}"
    echo "${BOLD}${C}  ╚══════════════════════════════════════════════╝${X}"
    echo ""
    echo "  ${BOLD}Progreso total${X} ${DIM}(meta: 1000)${X}"
    echo "  $bar  ${BOLD}$total${X}${DIM}/1000${X}  ${DIM}(${solo_pct}% solo)${X}"
    echo ""
    echo "  ${G}Solo (hard):${X}    ${BOLD}$solo${X}"
    echo "  ${Y}Con hint:${X}       ${BOLD}$hint${X}"
    echo "  ${C}En sandbox:${X}     ${BOLD}$sb${X} problemas"
    echo ""
    echo "  ${BOLD}Este mes${X} ${DIM}(meta: 150)${X}"
    echo "  $mbar  ${BOLD}$mc${X}${DIM}/150${X}  ${DIM}($((mc*100/150))%)${X}"
    echo ""
    echo "  ${BOLD}Racha:${X}  ${M}${BOLD}$streak días 🔥${X}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
# LOG
# ═══════════════════════════════════════════════════════════════════

_cb_log() {
    _cb_init
    echo ""
    echo "${BOLD}${C}  ☕  Historial — últimos 20${X}"
    _sep
    if [[ ! -s "$CPBREW_STATS/log" ]]; then
        echo "  ${DIM}Vacío. Usa ${C}cpbrew done${DIM} para registrar.${X}"
    else
        tail -20 "$CPBREW_STATS/log" | while IFS= read -r line; do
            local d n mode r out
            d=$(echo "$line" | cut -d'|' -f1 | tr -d ' ')
            n=$(echo "$line" | cut -d'|' -f2 | sed 's/^ *//;s/ *$//')
            mode=$(echo "$line" | cut -d'|' -f3 | tr -d ' ')
            r=$(echo "$line" | cut -d'|' -f4 | sed 's/^ *//;s/ *$//')
            out=$(echo "$line" | cut -d'|' -f5- | sed 's/^ *//;s/ *$//')

            if [[ -z "$r" ]]; then
                r="$mode"
                mode="LEGACY"
                out="-"
            fi

            if [[ "$mode" == "RETRY" ]]; then
                printf "  ${DIM}%s${X}  ${C}↺${X} ${BOLD}%s${X} ${DIM}(%s · %s)${X}\n" "$d" "$n" "$mode" "$r"
            elif [[ "$r" == "solo" ]]; then
                printf "  ${DIM}%s${X}  ${G}✓${X} ${BOLD}%s${X} ${DIM}(%s)${X}\n" "$d" "$n" "$r"
            else
                printf "  ${DIM}%s${X}  ${Y}~${X} ${BOLD}%s${X} ${DIM}(%s)${X}\n" "$d" "$n" "$r"
            fi
            [[ -n "$out" && "$out" != "-" ]] && echo "      ${DIM}→ $out${X}"
        done
    fi
    _sep
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
# STREAK
# ═══════════════════════════════════════════════════════════════════

_cb_streak() {
    _cb_init
    local streak=$(cat "$CPBREW_STATS/streak")
    local last=$(cat "$CPBREW_STATS/last_date")
    echo ""
    echo "  ${M}${BOLD}☕  $streak días de racha 🔥${X}"
    echo "  ${DIM}Último registro: $last${X}"
    echo ""
}

_cb_repo() {
    [[ "$1" == "help" || -z "$1" ]] && _cb_help_repo && return
    local url="$1"
    local curr="$PWD"
    cd "$CPBREW_ROOT" || return 1

    if [[ ! -d .git ]]; then
        git init >/dev/null 2>&1
        _ok "Repo git inicializado en ${BOLD}$CPBREW_ROOT${X}"
    fi

    if git remote get-url origin >/dev/null 2>&1; then
        git remote set-url origin "$url" || { _err "No se pudo actualizar origin."; cd "$curr"; return 1; }
        _ok "origin actualizado"
    else
        git remote add origin "$url" || { _err "No se pudo agregar origin."; cd "$curr"; return 1; }
        _ok "origin agregado"
    fi

    echo "  ${DIM}origin → $(git remote get-url origin)${X}"
    cd "$curr" || return 1
}

# ═══════════════════════════════════════════════════════════════════
# GIT
# ═══════════════════════════════════════════════════════════════════

_cb_git() {
    [[ "$1" == "help" ]] && _cb_help_git && return
    local curr=$(pwd)
    cd "$CPBREW_ROOT"
    echo ""
    local current_branch=$(git branch --show-current 2>/dev/null)
    local branches=($(git branch 2>/dev/null | tr -d '* '))
    echo "  ${BOLD}Branches:${X}"
    local i=1
    for b in $branches; do
        if [[ "$b" == "$current_branch" ]]; then
            printf "  ${G}%d) %s ${DIM}(actual)${X}\n" $i "$b"
        else
            printf "  ${DIM}%d) %s${X}\n" $i "$b"
        fi
        i=$((i+1))
    done
    echo -n "  Elige branch (Enter = ${BOLD}$current_branch${X}): "
    read branch_choice
    if [[ -n "$branch_choice" && "$branch_choice" =~ ^[0-9]+$ ]]; then
        local chosen="${branches[$branch_choice]}"
        [[ -n "$chosen" ]] && git checkout "$chosen" 2>/dev/null && _ok "Branch: ${BOLD}$chosen${X}"
    else
        _ok "Branch: ${BOLD}$current_branch${X}"
    fi
    echo ""
    _info "git add ."
    git add .
    echo -n "  Commit message (Enter = fecha automática): "
    read msg
    [[ -z "$msg" ]] && msg="solve: $(_today)"
    git commit -m "$msg"
    git push
    echo ""
    _ok "Push exitoso → ${BOLD}$msg${X}"
    echo ""
    cd "$curr"
}

# ═══════════════════════════════════════════════════════════════════
# ROUTER
# ═══════════════════════════════════════════════════════════════════

cpbrew() {
    _cb_load_config
    local cmd=$1
    shift
    case $cmd in
        init)         _cb_init_root "$@" ;;
        go)           _cb_go "$@" ;;
        ls)           _cb_ls ;;
        dest)         _cb_dest "$@" ;;
        new)          _cb_new "$@" ;;
        done)         _cb_done "$@" ;;
        log)          _cb_log ;;
        stats)        _cb_stats "$@" ;;
        streak)       _cb_streak ;;
        sb|sandbox)   _cb_sandbox "$@" ;;
        retry)        _cb_sandbox retry "$@" ;;
        stop)         _cb_sandbox stop ;;
        import)       _cb_import "$@" ;;
        repo)         _cb_repo "$@" ;;
        git)          _cb_git "$@" ;;
        help|"")      _cb_help_main ;;
        *)
            _err "Comando '${cmd}' no reconocido."
            echo "  Usa ${C}cpbrew help${X} para ver todos los comandos."
            ;;
    esac
}
