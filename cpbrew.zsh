#!/bin/zsh

# ╔═══════════════════════════════════════════════════════════════════╗
# ║  ☕  cpbrew — CLI de Programación Competitiva                    ║
# ║  Agustin Alexis Reyes Castillo · coffeeMeitt                    ║
# ║                                                                   ║
# ║  INSTALACIÓN:                                                     ║
# ║    echo 'source /ruta/a/cpbrew.zsh' >> ~/.zshrc                  ║
# ║    source ~/.zshrc                                                ║
# ╚═══════════════════════════════════════════════════════════════════╝

# ─── Paths absolutos ─────────────────────────────────────────────────────────
_CODE="$(command -v code 2>/dev/null)"
_MKDIR="/bin/mkdir"
_DATE="/bin/date"
_SED="/usr/bin/sed"
_CURL="/usr/bin/curl"
_CP="/bin/cp"

# ─── Config ──────────────────────────────────────────────────────────────────
CPBREW_ROOT="/Users/coffee/00-personal/cp_solutions"
CPBREW_STATS="$HOME/.cpbrew_stats"
CPBREW_SANDBOX="$CPBREW_ROOT/.sandbox"
CPBREW_META="$CPBREW_SANDBOX/.meta"

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
_sep()       { echo "${DIM}  ────────────────────────────────────────────${X}"; }
_ok()        { echo "  ${G}✓${X} $1"; }
_err()       { echo "  ${R}✗${X} $1"; }
_warn()      { echo "  ${Y}⚠${X}  $1"; }
_info()      { echo "  ${C}→${X} $1"; }
_today()     { $_DATE +%Y-%m-%d; }
_yesterday() { $_DATE -v-1d +%Y-%m-%d; }
_month()     { $_DATE +%Y-%m; }

# ─── Detectar archivo más reciente en sandbox ─────────────────────────────────
_cb_detect_active() {
    # Devuelve el nombre (sin .cpp) del archivo .cpp más recientemente modificado en sandbox
    local newest
    newest=$(ls -t "$CPBREW_SANDBOX"/*.cpp 2>/dev/null | head -1)
    if [[ -n "$newest" ]]; then
        basename "$newest" .cpp
    fi
}

# ─── Init ────────────────────────────────────────────────────────────────────
_cb_init() {
    $_MKDIR -p "$CPBREW_STATS" "$CPBREW_SANDBOX" "$CPBREW_META"
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

# ─── Metadata helpers ────────────────────────────────────────────────────────
_cb_meta_get() {
    local name=$1 key=$2
    grep "^${key}=" "$CPBREW_META/${name}.txt" 2>/dev/null | head -1 | cut -d= -f2-
}

_cb_meta_set() {
    local name=$1 key=$2 value=$3
    local file="$CPBREW_META/${name}.txt"
    if [[ -f "$file" ]] && grep -q "^${key}=" "$file"; then
        $_SED -i '' "s|^${key}=.*|${key}=${value}|" "$file"
    else
        echo "${key}=${value}" >> "$file"
    fi
}

_cb_meta_init() {
    local name=$1
    local file="$CPBREW_META/${name}.txt"
    if [[ ! -f "$file" ]]; then
        printf "nombre=%s\ncreado=%s\nattempts=0\ndone_once=0\n" \
            "$name" "$(_today)" > "$file"
    fi
}

# ─── Attempts helpers ────────────────────────────────────────────────────────
_cb_attempts_dir() {
    echo "$CPBREW_META/${1}_attempts"
}

_cb_next_attempt() {
    local name=$1
    local dir="$(_cb_attempts_dir "$name")"
    $_MKDIR -p "$dir"
    local count=$(ls "$dir"/*.cpp 2>/dev/null | wc -l | tr -d ' ')
    echo $((count + 1))
}

_cb_save_attempt() {
    local name=$1
    local src="$CPBREW_SANDBOX/${name}.cpp"
    local dir="$(_cb_attempts_dir "$name")"
    $_MKDIR -p "$dir"
    local n=$(_cb_next_attempt "$name")
    local dest="$dir/${name}_attempt_${n}.cpp"
    $_CP "$src" "$dest"
    _cb_meta_set "$name" "attempts" "$n"
    echo "$dest"
}

# ─── Templates C++ ────────────────────────────────────────────────────────────
_cb_write_original_template() {
    local file=$1
    cat > "$file" << CPPTEMPLATE
/*
Autor: Agustin Alexis Reyes Castillo
CF:    codeforces.com/profile/coffeeMeitt
CSES:  cses.fi/user/318632

IDEA:
*/

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

_cb_write_retry_template() {
    local file=$1
    local user_template="$CPBREW_ROOT/template.cpp"
    if [[ -f "$user_template" ]]; then
        $_CP "$user_template" "$file"
    else
        _warn "No encontré ${BOLD}$user_template${X}; usando template original."
        _cb_write_original_template "$file"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# HELP
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
    printf "  ${G}%-32s${X} %s\n" "cpbrew go <destino>"      "Abrir carpeta en VSCode"
    printf "  ${G}%-32s${X} %s\n" "cpbrew ls"                "Ver todos los destinos"
    echo ""
    _sep
    echo "  ${BOLD}SANDBOX — flujo principal${X}"
    _sep
    printf "  ${G}%-32s${X} %s\n" "cpbrew new <nombre>"      "Crear problema en sandbox"
    printf "  ${G}%-32s${X} %s\n" "cpbrew done"              "Guardar solución + registrar"
    printf "  ${G}%-32s${X} %s\n" "cpbrew retry"             "Borrar código y reintentar"
    printf "  ${G}%-32s${X} %s\n" "cpbrew diff <nombre>"     "Comparar attempts en VSCode"
    printf "  ${G}%-32s${X} %s\n" "cpbrew sb ls"             "Ver todos los problemas"
    printf "  ${G}%-32s${X} %s\n" "cpbrew sb start"          "Iniciar watch CPH background"
    printf "  ${G}%-32s${X} %s\n" "cpbrew sb stop"           "Detener watch"
    printf "  ${G}%-32s${X} %s\n" "cpbrew sb status"         "Estado del watch"
    echo ""
    _sep
    echo "  ${BOLD}IMPORT & STATS${X}"
    _sep
    printf "  ${G}%-32s${X} %s\n" "cpbrew import <url|ruta>" "Importar solución + diff"
    printf "  ${G}%-32s${X} %s\n" "cpbrew stats"             "Ver progreso y barras"
    printf "  ${G}%-32s${X} %s\n" "cpbrew streak"            "Ver racha actual"
    printf "  ${G}%-32s${X} %s\n" "cpbrew log [filtro]"      "Historial (all/last/find/unique)"
    printf "  ${G}%-32s${X} %s\n" "cpbrew reset -a|-r|-f"    "Borrar problemas/retrys"
    printf "  ${G}%-32s${X} %s\n" "cpbrew git"               "add + commit + push"
    echo ""
    echo "  ${DIM}Tip: ${C}cpbrew <cmd> help${X}${DIM} para ayuda individual.${X}"
    echo ""
}

_cb_help_go() {
    echo ""
    echo "${BOLD}${C}  cpbrew go${X} — Navegar a carpeta y abrir VSCode"
    _sep
    echo "  ${BOLD}Uso:${X} ${G}cpbrew go <destino>${X}"
    echo "  Usa ${C}cpbrew ls${X} para ver destinos disponibles."
    echo ""
}

_cb_help_new() {
    echo ""
    echo "${BOLD}${C}  cpbrew new${X} — Crear problema nuevo en sandbox"
    _sep
    echo "  ${BOLD}Uso:${X} ${G}cpbrew new <nombre>${X}"
    echo ""
    echo "  Crea ${DIM}.sandbox/<nombre>.cpp${X} con header de autor + IDEA."
    echo "  Flujo normal: new → resolver → done"
    echo "  Flujo retry:  done → retry → resolver → done"
    echo ""
}

_cb_help_done() {
    echo ""
    echo "${BOLD}${C}  cpbrew done${X} — Guardar solución"
    _sep
    echo "  ${BOLD}Uso:${X} ${G}cpbrew done${X}"
    echo ""
    echo "  Detecta automáticamente el .cpp más reciente en sandbox."
    echo "  Te muestra el nombre detectado y puedes cambiarlo."
    echo ""
    echo "  ${BOLD}Primera vez (done_once=0):${X}"
    echo "  → Copia el código a la carpeta destino que elijas"
    echo "  → Guarda una copia en attempts como attempt_1"
    echo ""
    echo "  ${BOLD}Retry (done_once=1):${X}"
    echo "  → NO copia a carpeta destino (ya existe)"
    echo "  → Guarda en attempts como attempt_N"
    echo ""
}

_cb_help_log() {
    echo ""
    echo "${BOLD}${C}  cpbrew log${X} — Historial de problemas"
    _sep
    echo "  ${BOLD}Uso:${X}"
    echo "    ${G}cpbrew log${X}               ${DIM}# todo el historial${X}"
    echo "    ${G}cpbrew log -unique${X}       ${DIM}# solo originales (NEW)${X}"
    echo "    ${G}cpbrew log last 15${X}       ${DIM}# últimos 15${X}"
    echo "    ${G}cpbrew log find divisors${X} ${DIM}# búsqueda por palabra${X}"
    echo "    ${G}cpbrew log --oneline${X}     ${DIM}# formato compacto (1 línea c/u)${X}"
    echo "    ${G}cpbrew log find divisors -unique last 10${X} ${DIM}# filtros combinados${X}"
    echo "    ${G}cpbrew log find dp --oneline last 8 -unique${X} ${DIM}# mezclado${X}"
    echo ""
}

_cb_help_retry() {
    echo ""
    echo "${BOLD}${C}  cpbrew retry${X} — Reintentar problema"
    _sep
    echo "  ${BOLD}Uso:${X} ${G}cpbrew retry${X} o ${G}cpbrew retry <nombre>${X}"
    echo ""
    echo "  Detecta el problema activo (más reciente en sandbox)."
    echo "  Borra el código del archivo .sandbox/<nombre>.cpp"
    echo "  y lo reinicia usando ${C}template.cpp${X}."
    echo "  El historial de attempts NO se borra."
    echo ""
}

_cb_help_git() {
    echo ""
    echo "${BOLD}${C}  cpbrew git${X} — Push rápido"
    _sep
    echo "  Lista branches, elige, hace add + commit + push."
    echo "  Enter en mensaje = fecha automática."
    echo "  Enter en branch = mantiene la actual."
    echo ""
}

_cb_help_import() {
    echo ""
    echo "${BOLD}${C}  cpbrew import${X} — Importar solución"
    _sep
    echo "  ${G}cpbrew import <url>${X}   Desde GitHub (raw o normal)"
    echo "  ${G}cpbrew import <ruta>${X}  Desde archivo local"
    echo ""
    echo "  ${DIM}Links normales de GitHub se convierten a raw automáticamente.${X}"
    echo ""
}

_cb_help_sb() {
    echo ""
    echo "${BOLD}${C}  cpbrew sb${X} — Subcomandos del sandbox"
    _sep
    printf "  ${G}%-28s${X} %s\n" "cpbrew sb ls"     "Listar problemas en sandbox"
    printf "  ${G}%-28s${X} %s\n" "cpbrew sb start"  "Iniciar watch CPH (background)"
    printf "  ${G}%-28s${X} %s\n" "cpbrew sb stop"   "Detener watch"
    printf "  ${G}%-28s${X} %s\n" "cpbrew sb status" "Estado del watch"
    echo ""
}

_cb_help_stats() {
    echo ""
    echo "${BOLD}${C}  cpbrew stats${X} — Progreso"
    _sep
    echo "  Barras hacia 1000 problemas totales y 150 este mes."
    echo "  Metas automáticas: 50, 100, 200, 300, 500, 750, 1000."
    echo ""
}

_cb_help_reset() {
    echo ""
    echo "${BOLD}${C}  cpbrew reset${X} — Limpieza de problemas/retries"
    _sep
    echo "  ${BOLD}Uso:${X}"
    echo "    ${G}cpbrew reset -a${X}           ${DIM}# borra todos los problemas + retries + log${X}"
    echo "    ${G}cpbrew reset -r${X}           ${DIM}# borra solo retries + entradas RETRY del log${X}"
    echo "    ${G}cpbrew reset -f <folder>${X}  ${DIM}# borra una carpeta específica + su log${X}"
    echo ""
    echo "  Ejemplos: ${C}cpbrew reset -f math${X}, ${C}cpbrew reset -f dp${X}"
    echo ""
}

_cb_dest_path_from_key() {
    local key="$1"
    case "$key" in
        intro)   echo "CSES/introductory_problems" ;;
        sort)    echo "CSES/sorting_and_searching" ;;
        dp)      echo "CSES/dynamic_programming" ;;
        graph)   echo "CSES/graph_algorithms" ;;
        agraph)  echo "CSES/advanced_graph_problems" ;;
        tree)    echo "CSES/tree_algorithms" ;;
        range)   echo "CSES/range_queries" ;;
        math)    echo "CSES/mathematics" ;;
        string)  echo "CSES/string_algorithms" ;;
        count)   echo "CSES/counting_problems" ;;
        bitwise) echo "CSES/bitwise_operations" ;;
        geo)     echo "CSES/geometry" ;;
        slide)   echo "CSES/sliding_window_problems" ;;
        const)   echo "CSES/construction_problems" ;;
        inter)   echo "CSES/interactive_problems" ;;
        adv)     echo "CSES/advanced_techniques" ;;
        add1)    echo "CSES/additional_problems_I" ;;
        add2)    echo "CSES/additional_problems_II" ;;
        cf)      echo "CODEFORCES" ;;
        icpc)    echo "ICPC/regionales" ;;
        sim)     echo "ICPC/simulacros" ;;
        sandbox) echo ".sandbox" ;;
        root)    echo "" ;;
        *)       return 1 ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# GO
# ═══════════════════════════════════════════════════════════════════

_cb_go() {
    [[ "$1" == "help" ]] && _cb_help_go && return
    local dest=$1
    if [[ -z "$dest" ]]; then
        _err "Especifica un destino. Usa ${C}cpbrew ls${X}."
        return 1
    fi
    local rel_path="$(_cb_dest_path_from_key "$dest")"
    [[ $? -ne 0 ]] && _err "Destino '${dest}' no encontrado. Usa ${C}cpbrew ls${X}." && return 1
    local fullpath="$CPBREW_ROOT/$rel_path"
    $_MKDIR -p "$fullpath"
    cd "$fullpath"
    _ok "${BOLD}$fullpath${X}"
    "$_CODE" .
}

# ═══════════════════════════════════════════════════════════════════
# LS
# ═══════════════════════════════════════════════════════════════════

_cb_ls() {
    echo ""
    echo "${BOLD}${C}  ☕  Destinos disponibles${X}"
    echo ""
    echo "${BOLD}  ── CSES ──────────────────────────────────────────${X}"
    printf "  ${Y}%-10s${X} ${DIM}%-28s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "intro"   "introductory_problems"   "sort"    "sorting_and_searching"
    printf "  ${Y}%-10s${X} ${DIM}%-28s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "dp"      "dynamic_programming"     "graph"   "graph_algorithms"
    printf "  ${Y}%-10s${X} ${DIM}%-28s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "agraph"  "advanced_graph_problems" "tree"    "tree_algorithms"
    printf "  ${Y}%-10s${X} ${DIM}%-28s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "range"   "range_queries"           "math"    "mathematics"
    printf "  ${Y}%-10s${X} ${DIM}%-28s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "string"  "string_algorithms"       "count"   "counting_problems"
    printf "  ${Y}%-10s${X} ${DIM}%-28s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "bitwise" "bitwise_operations"      "geo"     "geometry"
    printf "  ${Y}%-10s${X} ${DIM}%-28s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "slide"   "sliding_window_problems" "const"   "construction_problems"
    printf "  ${Y}%-10s${X} ${DIM}%-28s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "inter"   "interactive_problems"    "adv"     "advanced_techniques"
    printf "  ${Y}%-10s${X} ${DIM}%-28s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "add1"    "additional_problems_I"   "add2"    "additional_problems_II"
    echo ""
    echo "${BOLD}  ── OTRAS ─────────────────────────────────────────${X}"
    printf "  ${Y}%-10s${X} ${DIM}%-28s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "cf"      "CODEFORCES"              "icpc"    "ICPC/regionales"
    printf "  ${Y}%-10s${X} ${DIM}%-28s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "sim"     "ICPC/simulacros"         "sandbox" ".sandbox"
    printf "  ${Y}%-10s${X} ${DIM}%s${X}\n"                                "root"    "raíz del repo"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
# NEW
# ═══════════════════════════════════════════════════════════════════

_cb_new() {
    [[ "$1" == "help" ]] && _cb_help_new && return
    local name=$1
    if [[ -z "$name" ]]; then
        _err "Especifica un nombre. Ej: ${C}cpbrew new 1900A${X}"
        return 1
    fi
    _cb_init
    local file="$CPBREW_SANDBOX/${name}.cpp"
    if [[ -f "$file" ]]; then
        _warn "Ya existe ${BOLD}$name${X} en sandbox. Usa ${C}cpbrew retry $name${X} para reintentar."
        return 1
    fi
    $_MKDIR -p "$CPBREW_SANDBOX"
    _cb_write_original_template "$file"
    _cb_meta_init "$name"
    echo ""
    _ok "Creado ${BOLD}$name${X} en sandbox"
    echo "  ${DIM}$file${X}"
    echo ""
    "$_CODE" "$file"
}

# ═══════════════════════════════════════════════════════════════════
# DONE — guarda solución, registra stats
# ═══════════════════════════════════════════════════════════════════

_cb_done() {
    [[ "$1" == "help" ]] && _cb_help_done && return
    _cb_init

    # ── Detectar archivo activo ──────────────────────────────────
    local detected=$(_cb_detect_active)
    echo ""
    echo "${BOLD}${C}  ☕  cpbrew done${X}"
    _sep
    if [[ -n "$detected" ]]; then
        echo -n "  Problema (Enter = ${BOLD}$detected${X}): "
    else
        echo -n "  Problema: "
    fi
    read name
    [[ -z "$name" ]] && name="$detected"
    if [[ -z "$name" ]]; then
        _err "No se detectó ningún problema activo."
        return 1
    fi

    local sb_file="$CPBREW_SANDBOX/${name}.cpp"
    if [[ ! -f "$sb_file" ]]; then
        _err "No existe ${BOLD}$sb_file${X}. Usa ${C}cpbrew new $name${X} primero."
        return 1
    fi

    # ── Verificar que el archivo tiene código ────────────────────
    local line_count=$(wc -l < "$sb_file" | tr -d ' ')
    if [[ $line_count -lt 5 ]]; then
        _warn "El archivo parece estar vacío o tiene muy poco código."
        echo -n "  ¿Continuar de todas formas? [y/N]: "
        read confirm
        [[ "$confirm" != "y" && "$confirm" != "Y" ]] && return 1
    fi

    _cb_meta_init "$name"
    local done_once=$(_cb_meta_get "$name" "done_once")
    [[ -z "$done_once" ]] && done_once=0

    # ── Guardar attempt ──────────────────────────────────────────
    local attempt_file=$(_cb_save_attempt "$name")
    local attempt_n=$(_cb_meta_get "$name" "attempts")
    _ok "Attempt #${attempt_n} guardado"
    echo "  ${DIM}→ $attempt_file${X}"

    # ── Si es primera vez: copiar a carpeta destino ──────────────
    if [[ "$done_once" == "0" ]]; then
        echo ""
        echo "  ${BOLD}Primera solución — ¿dónde guardar?${X}"
        echo "  ${DIM}Destinos: math, cf, dp, graph, sort, etc. (Enter = math)${X}"
        echo -n "  Destino: "
        read dest_key
        [[ -z "$dest_key" ]] && dest_key="math"

        local dest_path=""
        case $dest_key in
            intro)   dest_path="CSES/introductory_problems" ;;
            sort)    dest_path="CSES/sorting_and_searching" ;;
            dp)      dest_path="CSES/dynamic_programming" ;;
            graph)   dest_path="CSES/graph_algorithms" ;;
            agraph)  dest_path="CSES/advanced_graph_problems" ;;
            tree)    dest_path="CSES/tree_algorithms" ;;
            range)   dest_path="CSES/range_queries" ;;
            math)    dest_path="CSES/mathematics" ;;
            string)  dest_path="CSES/string_algorithms" ;;
            count)   dest_path="CSES/counting_problems" ;;
            bitwise) dest_path="CSES/bitwise_operations" ;;
            geo)     dest_path="CSES/geometry" ;;
            slide)   dest_path="CSES/sliding_window_problems" ;;
            const)   dest_path="CSES/construction_problems" ;;
            inter)   dest_path="CSES/interactive_problems" ;;
            adv)     dest_path="CSES/advanced_techniques" ;;
            add1)    dest_path="CSES/additional_problems_I" ;;
            add2)    dest_path="CSES/additional_problems_II" ;;
            cf)      dest_path="CODEFORCES" ;;
            icpc)    dest_path="ICPC/regionales" ;;
            sim)     dest_path="ICPC/simulacros" ;;
            root)    dest_path="" ;;
            *)       dest_path="$dest_key" ;;
        esac

        local dest_dir="$CPBREW_ROOT/$dest_path"
        $_MKDIR -p "$dest_dir"
        local dest_file="$dest_dir/${name}.cpp"

        # COPIAR EL ARCHIVO
        $_CP "$sb_file" "$dest_file"

        if [[ $? -eq 0 ]]; then
            _ok "Código copiado a ${BOLD}$dest_file${X}"
        else
            _err "Error al copiar. Revisa permisos."
            return 1
        fi

        _cb_meta_set "$name" "done_once" "1"
        _cb_meta_set "$name" "dest" "$dest_file"
    else
        echo ""
        echo "  ${Y}↺${X} Retry — código guardado solo en historial de attempts."
        local dest_file=$(_cb_meta_get "$name" "dest")
        if [[ -n "$dest_file" ]]; then
            echo "  ${DIM}Solución original en: $dest_file${X}"
        fi
    fi

    # ── Resultado ────────────────────────────────────────────────
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

    # ── Actualizar stats ─────────────────────────────────────────
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
    local entry_type="RETRY"
    local entry_ref="$attempt_file"
    [[ "$done_once" == "0" ]] && entry_type="NEW" && entry_ref="$dest_file"
    echo "$today | $name | $entry_type | attempt_${attempt_n} | $rstr | $entry_ref" >> "$CPBREW_STATS/log"

    echo ""
    _sep
    _ok "${BOLD}$name${X} — attempt #${attempt_n} registrado ${DIM}($rstr)${X}"
    echo "  Total: ${BOLD}$new_total${X}  ·  Racha: ${M}${BOLD}${streak} días 🔥${X}"
    _sep
    echo ""
    _cb_check_milestones $new_total
}

# ═══════════════════════════════════════════════════════════════════
# RETRY — borra el código del sandbox y escribe template limpio
# ═══════════════════════════════════════════════════════════════════

_cb_retry() {
    [[ "$1" == "help" ]] && _cb_help_retry && return
    _cb_init

    local name=$1
    if [[ -z "$name" ]]; then
        local detected=$(_cb_detect_active)
        if [[ -n "$detected" ]]; then
            echo -n "  Problema (Enter = ${BOLD}$detected${X}): "
        else
            echo -n "  Problema: "
        fi
        read name
        [[ -z "$name" ]] && name="$detected"
    fi

    if [[ -z "$name" ]]; then
        _err "No se detectó ningún problema activo."
        return 1
    fi

    local sb_file="$CPBREW_SANDBOX/${name}.cpp"
    if [[ ! -f "$sb_file" ]]; then
        _err "No existe ${BOLD}$sb_file${X}. Usa ${C}cpbrew new $name${X} primero."
        return 1
    fi

    # Borra el código y escribe template limpio
    _cb_write_retry_template "$sb_file"

    local attempts=$(_cb_meta_get "$name" "attempts")
    [[ -z "$attempts" ]] && attempts=0

    echo ""
    _ok "${BOLD}$name${X} listo para retry"
    echo "  ${DIM}Código borrado — template limpio en sandbox${X}"
    echo "  ${DIM}Attempts guardados hasta ahora: $attempts${X}"
    echo ""
    "$_CODE" "$sb_file"
}

# ═══════════════════════════════════════════════════════════════════
# DIFF
# ═══════════════════════════════════════════════════════════════════

_cb_diff() {
    local name=$1
    if [[ -z "$name" ]]; then
        local detected=$(_cb_detect_active)
        [[ -n "$detected" ]] && echo -n "  Problema (Enter = ${BOLD}$detected${X}): " || echo -n "  Problema: "
        read name
        [[ -z "$name" ]] && name="$detected"
    fi
    if [[ -z "$name" ]]; then
        _err "Especifica un problema."
        return 1
    fi
    local dir="$(_cb_attempts_dir "$name")"
    local files=($(ls "$dir"/*.cpp 2>/dev/null | sort))
    local count=${#files[@]}
    if [[ $count -lt 2 ]]; then
        _warn "Necesitas al menos 2 attempts para comparar."
        return 1
    fi
    echo ""
    echo "  ${BOLD}Attempts de $name:${X}"
    local i=1
    for f in $files; do
        printf "  ${Y}%2d)${X} %s\n" $i "$(basename "$f")"
        i=$((i+1))
    done
    echo -n "  Compara A: "
    read ia
    echo -n "  Compara B: "
    read ib
    local a="${files[$ia]}"
    local b="${files[$ib]}"
    if [[ -z "$a" || -z "$b" ]]; then
        _err "Índices inválidos."
        return 1
    fi
    echo ""
    _info "Abriendo diff..."
    echo "  ${DIM}A: $(basename $a)${X}"
    echo "  ${DIM}B: $(basename $b)${X}"
    echo ""
    "$_CODE" --diff "$a" "$b"
}

# ═══════════════════════════════════════════════════════════════════
# SANDBOX subcomandos
# ═══════════════════════════════════════════════════════════════════

_cb_sandbox() {
    local subcmd=$1
    [[ "$subcmd" == "help" || -z "$subcmd" ]] && _cb_help_sb && return
    shift

    case $subcmd in
        ls)
            echo ""
            echo "${BOLD}${C}  ☕  Sandbox — problemas${X}"
            _sep
            local files=($(ls "$CPBREW_SANDBOX"/*.cpp 2>/dev/null))
            if [[ ${#files[@]} -eq 0 ]]; then
                echo "  ${DIM}Vacío. Usa ${C}cpbrew new <nombre>${DIM}.${X}"
            else
                printf "  ${BOLD}%-28s  %-8s  %-8s  %s${X}\n" "Problema" "Attempts" "1ª vez" "Guardado en"
                _sep
                for f in $files; do
                    local n=$(basename "$f" .cpp)
                    local attempts=$(_cb_meta_get "$n" "attempts")
                    [[ -z "$attempts" ]] && attempts=0
                    local done_once=$(_cb_meta_get "$n" "done_once")
                    [[ -z "$done_once" ]] && done_once=0
                    local dest=$(_cb_meta_get "$n" "dest")
                    [[ -z "$dest" ]] && dest="${DIM}pendiente${X}"
                    local done_str="${R}no${X}"
                    [[ "$done_once" == "1" ]] && done_str="${G}sí${X}"
                    printf "  ${Y}%-28s${X}  ${G}%-8s${X}  " "$n" "$attempts"
                    echo -n "$done_str"
                    printf "  ${DIM}%s${X}\n" "$dest"
                done
                _sep
            fi
            echo ""
            ;;

        start|watch)
            local watch_dir=$(pwd)
            local pidfile="$CPBREW_STATS/watch.pid"
            local logfile="$CPBREW_STATS/watch.log"
            if [[ -f "$pidfile" ]] && kill -0 "$(cat $pidfile)" 2>/dev/null; then
                _warn "Watch ya está corriendo (PID $(cat $pidfile)). Usa ${C}cpbrew sb stop${X}."
                return 1
            fi
            {
                local known_files=($(ls "$watch_dir"/*.cpp 2>/dev/null))
                echo "[$(date '+%H:%M:%S')] Watch iniciado en: $watch_dir" >> "$logfile"
                while true; do
                    sleep 2
                    local current_files=($(ls "$watch_dir"/*.cpp 2>/dev/null))
                    for f in $current_files; do
                        local found=0
                        for k in $known_files; do
                            [[ "$f" == "$k" ]] && found=1 && break
                        done
                        if [[ $found -eq 0 ]]; then
                            local fname=$(basename "$f" .cpp)
                            local target="$CPBREW_SANDBOX/${fname}.cpp"
                            $_CP "$f" "$target"
                            _cb_meta_init "$fname"
                            echo "[$(date '+%H:%M:%S')] CPH: $fname → sandbox" >> "$logfile"
                            known_files=("${current_files[@]}")
                        fi
                    done
                done
            } &
            local pid=$!
            echo $pid > "$pidfile"
            disown $pid
            echo ""
            _ok "Watch iniciado ${DIM}(PID $pid)${X}"
            echo "  ${DIM}Carpeta monitoreada: $watch_dir${X}"
            echo "  ${DIM}Log: $logfile${X}"
            echo "  ${DIM}Detener con: ${C}cpbrew sb stop${X}"
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
                kill "$pid" && rm -f "$pidfile"
                echo ""; _ok "Watch detenido (PID $pid)"; echo ""
            else
                rm -f "$pidfile"
                _warn "El proceso ya no existía. Limpiado."
            fi
            ;;

        status)
            local pidfile="$CPBREW_STATS/watch.pid"
            local logfile="$CPBREW_STATS/watch.log"
            echo ""
            if [[ -f "$pidfile" ]] && kill -0 "$(cat $pidfile)" 2>/dev/null; then
                _ok "Watch corriendo ${DIM}(PID $(cat $pidfile))${X}"
                echo ""
                echo "  ${BOLD}Últimas detecciones:${X}"
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
        _err "Especifica URL o ruta. Usa ${C}cpbrew import help${X}."
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
    echo -n "  ¿Comparar con otro archivo? (ruta o Enter): "
    read cmp
    [[ -n "$cmp" && -f "$cmp" ]] && "$_CODE" --diff "$cmp" "$dest" || "$_CODE" "$dest"
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
    local sb=$(ls "$CPBREW_SANDBOX"/*.cpp 2>/dev/null | wc -l | tr -d ' ')
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
    emulate -L zsh
    setopt noxtrace noverbose typesetsilent
    set +x +v 2>/dev/null
    _cb_init
    [[ "$1" == "help" ]] && _cb_help_log && return

    local want_unique=0
    local one_line=0
    local limit=0
    local query=""
    local token
    while (( $# > 0 )); do
        token="$1"
        case "$token" in
            -unique|unique)
                want_unique=1
                shift
                ;;
            --oneline|-oneline|oneline)
                one_line=1
                shift
                ;;
            last)
                shift
                [[ $# -eq 0 ]] && _err "Usa: cpbrew log last <numero>" && return 1
                [[ ! "$1" =~ ^[0-9]+$ ]] && _err "Usa: cpbrew log last <numero>" && return 1
                limit="$1"
                shift
                ;;
            find)
                shift
                [[ $# -eq 0 ]] && _err "Usa: cpbrew log find <texto>" && return 1
                while (( $# > 0 )); do
                    case "$1" in
                        -unique|unique|--oneline|-oneline|oneline|last|find|help) break ;;
                        *)
                            [[ -n "$query" ]] && query+=" "
                            query+="$1"
                            shift
                            ;;
                    esac
                done
                ;;
            help)
                _cb_help_log
                return
                ;;
            *)
                _err "Filtro no reconocido: $token"
                echo "  Usa: cpbrew log [find <texto>] [-unique] [--oneline] [last <numero>]"
                return 1
                ;;
        esac
    done

    echo ""
    if [[ ! -s "$CPBREW_STATS/log" ]]; then
        echo "  ${DIM}log vacío. Usa ${C}cpbrew done${DIM}.${X}"
    else
        local -a rows
        local line
        while IFS= read -r line; do
            local f1 f2 f3 f4 f5 f6
            IFS='|' read -r f1 f2 f3 f4 f5 f6 <<< "$line"

            local d n t a r ref
            d=$(echo "$f1" | sed 's/^ *//;s/ *$//')
            n=$(echo "$f2" | sed 's/^ *//;s/ *$//')
            t=$(echo "$f3" | sed 's/^ *//;s/ *$//')
            a=$(echo "$f4" | sed 's/^ *//;s/ *$//')
            r=$(echo "$f5" | sed 's/^ *//;s/ *$//')
            ref=$(echo "$f6" | sed 's/^ *//;s/ *$//')

            # Compatibilidad con formatos viejos.
            if [[ -z "$r" ]]; then
                if [[ "$t" == "NEW" || "$t" == "RETRY" || "$t" == "NORMAL" ]]; then
                    r="$a"
                    a="-"
                    [[ "$t" == "NORMAL" ]] && t="NEW"
                elif [[ "$t" == attempt_* ]]; then
                    local old_r="$a"
                    a="$t"
                    t="RETRY"
                    r="$old_r"
                else
                    r="$t"
                    t="NEW"
                    a="-"
                fi
            fi

            [[ "$t" == "NORMAL" ]] && t="NEW"
            [[ -z "$a" ]] && a="-"

            # Compatibilidad: formato viejo de 5 campos:
            # date | name | NORMAL/RETRY | resultado | ruta
            if [[ -z "$ref" && "$t" =~ "^(NEW|RETRY)$" && "$a" != attempt_* ]]; then
                if [[ "$r" == *"/"* || "$r" == *.cpp || "$r" == *.cc ]]; then
                    ref="$r"
                    r="$a"
                    a="-"
                fi
            fi

            if (( want_unique == 1 )) && [[ "$t" != "NEW" ]]; then
                continue
            fi

            if [[ -n "$query" ]]; then
                local haystack="$(echo "$n $ref" | tr '[:upper:]' '[:lower:]')"
                local needle="$(echo "$query" | tr '[:upper:]' '[:lower:]')"
                [[ "$haystack" != *"$needle"* ]] && continue
            fi

            rows+=("$d|$n|$t|$a|$r|$ref")
        done < "$CPBREW_STATS/log"

        if (( limit > 0 )) && (( ${#rows[@]} > limit )); then
            rows=("${rows[@]: -$limit}")
        fi

        if (( ${#rows[@]} == 0 )); then
            echo "  ${DIM}Sin resultados para esos filtros.${X}"
            echo ""
            return
        fi

        local total_new=0
        local total_retry=0
        for line in "${rows[@]}"; do
            local _d _n _t _a _r _ref
            IFS='|' read -r _d _n _t _a _r _ref <<< "$line"
            [[ "$_t" == "NEW" ]] && total_new=$((total_new + 1)) || total_retry=$((total_retry + 1))
        done

        echo "  ${BOLD}${C}log${X} ${DIM}(${#rows[@]} · NEW:${total_new} · RETRY:${total_retry})${X}"
        echo ""

        for line in "${rows[@]}"; do
            local d n t a r ref
            IFS='|' read -r d n t a r ref <<< "$line"

            local mark="${C}•${X}"
            local type_col="${C}NEW${X}"
            [[ "$t" == "RETRY" ]] && mark="${Y}↺${X}" && type_col="${Y}RETRY${X}"
            local result_col="$r"
            [[ "$r" == "solo" ]] && result_col="${G}solo${X}"
            [[ "$r" == "1 hint" ]] && result_col="${Y}1 hint${X}"
            [[ "$r" == "2+ hints" ]] && result_col="${R}2+ hints${X}"

            if (( one_line == 1 )); then
                printf "  %b ${DIM}%s${X}  %b  ${BOLD}%s${X}  ${DIM}%s${X}  %b\n" "$mark" "$d" "$type_col" "$n" "$a" "$result_col"
            else
                printf "  %b ${DIM}%s${X}  %-16b ${BOLD}%-28s${X} ${DIM}%s${X} · %b\n" "$mark" "$d" "$type_col" "$n" "$a" "$result_col"
            fi
        done
    fi
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
    echo -n "  Branch (Enter = ${BOLD}$current_branch${X}): "
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
    echo ""; _ok "Push exitoso → ${BOLD}$msg${X}"; echo ""
    cd "$curr"
}

# ═══════════════════════════════════════════════════════════════════
# RESET helpers
# ═══════════════════════════════════════════════════════════════════

_cb_rebuild_stats_from_log() {
    local total=0 solo=0 hint=0 streak=0
    local today=$(_today)
    local last_date="$today"

    if [[ -s "$CPBREW_STATS/log" ]]; then
        total=$(wc -l < "$CPBREW_STATS/log" | tr -d ' ')
        solo=$(grep -E '\| *solo *\|' "$CPBREW_STATS/log" 2>/dev/null | wc -l | tr -d ' ')
        hint=$((total - solo))
        last_date=$(tail -1 "$CPBREW_STATS/log" | awk -F'|' '{gsub(/^ +| +$/, "", $1); print $1}')
        [[ -z "$last_date" ]] && last_date="$today"

        local -a days
        days=($(awk -F'|' '{gsub(/^ +| +$/, "", $1); if ($1 != "") print $1}' "$CPBREW_STATS/log" | sort -u))
        typeset -A dayset
        local d
        for d in $days; do dayset[$d]=1; done
        streak=1
        local cur="$last_date"
        while true; do
            local prev=$($_DATE -j -v-1d -f "%Y-%m-%d" "$cur" "+%Y-%m-%d" 2>/dev/null)
            [[ -z "$prev" || -z "${dayset[$prev]}" ]] && break
            streak=$((streak + 1))
            cur="$prev"
        done
    fi

    echo "$total" > "$CPBREW_STATS/total"
    echo "$solo" > "$CPBREW_STATS/solo"
    echo "$hint" > "$CPBREW_STATS/hint"
    echo "$streak" > "$CPBREW_STATS/streak"
    echo "$last_date" > "$CPBREW_STATS/last_date"
}

_cb_clear_cache() {
    echo ""
    _warn "Esto reiniciará historial + goals (total, streak, log, milestones)."
    echo -n "  ¿Confirmar? [y/N]: "
    read confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        rm -rf "$CPBREW_STATS"
        _cb_init
        _ok "Historial y goals reiniciados."
    else
        echo "  Cancelado."
    fi
    echo ""
}

_cb_reset() {
    _cb_init
    [[ "$1" == "help" || -z "$1" ]] && _cb_help_reset && return

    local mode="$1"
    case "$mode" in
        -a)
            echo ""
            _warn "Borrará TODOS los .cpp de CSES/CODEFORCES/ICPC/.sandbox y limpiará log."
            echo -n "  ¿Confirmar reset total? [y/N]: "
            read c
            [[ "$c" != "y" && "$c" != "Y" ]] && echo "  Cancelado." && echo "" && return

            local d
            for d in "$CPBREW_ROOT/CSES" "$CPBREW_ROOT/CODEFORCES" "$CPBREW_ROOT/ICPC" "$CPBREW_SANDBOX"; do
                [[ -d "$d" ]] && find "$d" -type f -name "*.cpp" -delete 2>/dev/null
            done
            rm -rf "$CPBREW_META"
            $_MKDIR -p "$CPBREW_META"
            : > "$CPBREW_STATS/log"
            : > "$CPBREW_STATS/milestones"
            _cb_rebuild_stats_from_log
            _ok "Reset total completado."
            echo ""
            ;;

        -r)
            echo ""
            _warn "Borrará todos los retries (snapshots) y entradas RETRY del log."
            echo -n "  ¿Confirmar reset de retries? [y/N]: "
            read c
            [[ "$c" != "y" && "$c" != "Y" ]] && echo "  Cancelado." && echo "" && return

            find "$CPBREW_META" -type d -name "*_attempts" -prune -exec rm -rf {} + 2>/dev/null
            local mf
            for mf in "$CPBREW_META"/*.txt; do
                [[ -f "$mf" ]] || continue
                if grep -q "^attempts=" "$mf"; then
                    $_SED -i '' 's/^attempts=.*/attempts=0/' "$mf"
                else
                    echo "attempts=0" >> "$mf"
                fi
            done

            local tmp="$CPBREW_STATS/log.tmp.$$"
            : > "$tmp"
            local line
            while IFS= read -r line; do
                local f1 f2 f3 f4 f5 f6 t
                IFS='|' read -r f1 f2 f3 f4 f5 f6 <<< "$line"
                t=$(echo "$f3" | $_SED 's/^ *//;s/ *$//')
                [[ "$t" == "RETRY" || "$t" == attempt_* ]] && continue
                echo "$line" >> "$tmp"
            done < "$CPBREW_STATS/log"
            mv "$tmp" "$CPBREW_STATS/log"
            _cb_rebuild_stats_from_log
            _ok "Retries reseteados."
            echo ""
            ;;

        -f)
            local folder="$2"
            [[ -z "$folder" ]] && _err "Usa: cpbrew reset -f <folder>" && return 1

            local rel="$(_cb_dest_path_from_key "$folder")"
            if [[ $? -ne 0 ]]; then
                [[ "$folder" == /* ]] && _err "Usa ruta relativa o alias de cpbrew ls." && return 1
                [[ -d "$CPBREW_ROOT/$folder" ]] && rel="$folder" || { _err "Carpeta no válida: $folder"; return 1; }
            fi

            local abs="$CPBREW_ROOT/$rel"
            [[ ! -d "$abs" ]] && _err "No existe: $abs" && return 1
            if [[ "$abs" == "$CPBREW_SANDBOX" || "$abs" == "$CPBREW_ROOT" ]]; then
                _err "Para sandbox o root usa reset -a."
                return 1
            fi

            echo ""
            _warn "Borrará .cpp en ${BOLD}$abs${X} y limpiará entradas relacionadas del log."
            echo -n "  ¿Confirmar reset de carpeta? [y/N]: "
            read c
            [[ "$c" != "y" && "$c" != "Y" ]] && echo "  Cancelado." && echo "" && return

            local -a names
            while IFS= read -r f; do
                names+=("$(basename "$f" .cpp)")
            done < <(find "$abs" -maxdepth 1 -type f -name "*.cpp" 2>/dev/null)

            find "$abs" -maxdepth 1 -type f -name "*.cpp" -delete 2>/dev/null

            local n
            for n in $names; do
                rm -f "$CPBREW_SANDBOX/${n}.cpp" "$CPBREW_META/${n}.txt"
                rm -rf "$CPBREW_META/${n}_attempts"
            done

            local tmp="$CPBREW_STATS/log.tmp.$$"
            : > "$tmp"
            local line
            while IFS= read -r line; do
                local f1 f2 f3 f4 f5 f6 nname ref skip
                IFS='|' read -r f1 f2 f3 f4 f5 f6 <<< "$line"
                nname=$(echo "$f2" | $_SED 's/^ *//;s/ *$//')
                ref=$(echo "$f6" | $_SED 's/^ *//;s/ *$//')
                skip=0
                for n in $names; do
                    [[ "$nname" == "$n" ]] && skip=1 && break
                done
                [[ $skip -eq 0 && -n "$ref" && "$ref" == "$abs/"* ]] && skip=1
                [[ $skip -eq 0 ]] && echo "$line" >> "$tmp"
            done < "$CPBREW_STATS/log"
            mv "$tmp" "$CPBREW_STATS/log"
            _cb_rebuild_stats_from_log
            _ok "Carpeta reseteada: ${BOLD}$rel${X}"
            echo ""
            ;;

        *)
            _err "Modo no válido. Usa ${C}cpbrew reset help${X}."
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# ROUTER
# ═══════════════════════════════════════════════════════════════════

cpbrew() {
    local cmd=$1
    shift
    case $cmd in
        go)           _cb_go "$@" ;;
        ls)           _cb_ls ;;
        new)          _cb_new "$@" ;;
        done)         _cb_done "$@" ;;
        retry)        _cb_retry "$@" ;;
        diff)         _cb_diff "$@" ;;
        sb|sandbox)   _cb_sandbox "$@" ;;
        import)       _cb_import "$@" ;;
        stats)        _cb_stats "$@" ;;
        streak)       _cb_streak ;;
        log)          _cb_log "$@" ;;
        git)          _cb_git "$@" ;;
        clear-cache)  _cb_clear_cache ;;
        reset)        _cb_reset "$@" ;;
        restart|reset-goals) _cb_clear_cache ;;
        help|"")      _cb_help_main ;;
        *)
            _err "Comando '${cmd}' no reconocido."
            echo "  Usa ${C}cpbrew help${X} para ver los comandos."
            ;;
    esac
}
