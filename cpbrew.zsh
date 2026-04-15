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
CPBREW_RETRIES="$CPBREW_ROOT/.retries"
CPBREW_PERSONAL="$CPBREW_ROOT/.cpbrew_personal"
CPBREW_SR_DEFAULT="3,7,14,30"
CPBREW_SR_REVIEW_CAP=10

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
_date_add_days() {
    local base="$1"
    local days="$2"
    $_DATE -j -v+"$days"d -f "%Y-%m-%d" "$base" "+%Y-%m-%d" 2>/dev/null
}

_sr_count_intervals() {
    local intervals="$1"
    echo "$intervals" | awk -F',' '{print NF}'
}

_sr_interval_at() {
    local intervals="$1"
    local idx="$2"
    echo "$intervals" | awk -F',' -v i="$idx" '{gsub(/ /, "", $0); print $i}'
}

_sr_compute_next_date() {
    local base_date="$1"
    local intervals="$2"
    local step="$3"
    local total=$(_sr_count_intervals "$intervals")
    if (( step >= total )); then
        echo "done"
        return
    fi
    local next_idx=$((step + 1))
    local days=$(_sr_interval_at "$intervals" "$next_idx")
    [[ -z "$days" ]] && echo "done" && return
    _date_add_days "$base_date" "$days"
}

_sr_last_date_from_log() {
    local name="$1"
    awk -F'|' -v n="$name" '
        {
            d=$1; nm=$2;
            gsub(/^ +| +$/, "", d);
            gsub(/^ +| +$/, "", nm);
            if (nm == n) last=d;
        }
        END { if (last != "") print last; }
    ' "$CPBREW_STATS/log"
}

# ─── CPH .prob helpers ───────────────────────────────────────────────────────
_cb_cph_find_prob() {
    local name="$1"
    local cph_dir="$CPBREW_SANDBOX/.cph"
    local f
    for f in "$cph_dir"/.${name}.cpp_*.prob(N); do
        [[ -f "$f" ]] && echo "$f" && return 0
    done
    return 1
}

_cb_cph_get_json_field() {
    local file="$1"
    local field="$2"
    grep -o "\"${field}\":\"[^\"]*\"" "$file" 2>/dev/null | head -1 | $_SED 's/.*":"\(.*\)"/\1/'
}

_cb_cph_read_prob() {
    local name="$1"
    local prob="$(_cb_cph_find_prob "$name")"
    [[ -z "$prob" ]] && return 1
    local url=$(_cb_cph_get_json_field "$prob" "url")
    local group=$(_cb_cph_get_json_field "$prob" "group")
    local display=$(_cb_cph_get_json_field "$prob" "name")
    [[ -n "$url" ]]     && _cb_meta_set "$name" "url" "$url"
    [[ -n "$group" ]]   && _cb_meta_set "$name" "group" "$group"
    [[ -n "$display" ]] && _cb_meta_set "$name" "display_name" "$display"
    return 0
}

_cb_cph_auto_dest() {
    local group="$1"
    if [[ "$group" == *Codeforces* ]]; then
        echo "cf"
    elif [[ "$group" == *AtCoder* || "$group" == *Atcoder* ]]; then
        echo "cf"
    fi
    # CSES: no podemos detectar subcategoría automáticamente → retorna vacío
}

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
    $_MKDIR -p "$CPBREW_STATS" "$CPBREW_SANDBOX" "$CPBREW_META" "$CPBREW_RETRIES"
    [[ ! -f "$CPBREW_STATS/total" ]]      && echo "0" > "$CPBREW_STATS/total"
    [[ ! -f "$CPBREW_STATS/solo" ]]       && echo "0" > "$CPBREW_STATS/solo"
    [[ ! -f "$CPBREW_STATS/hint" ]]       && echo "0" > "$CPBREW_STATS/hint"
    [[ ! -f "$CPBREW_STATS/streak" ]]     && echo "0" > "$CPBREW_STATS/streak"
    [[ ! -f "$CPBREW_STATS/last_date" ]]  && _today > "$CPBREW_STATS/last_date"
    [[ ! -f "$CPBREW_STATS/log" ]]        && touch "$CPBREW_STATS/log"
    [[ ! -f "$CPBREW_STATS/milestones" ]] && touch "$CPBREW_STATS/milestones"
    [[ ! -f "$CPBREW_PERSONAL" ]]         && touch "$CPBREW_PERSONAL"

    # Migración automática: viejo layout (.sandbox/.meta/<name>_attempts) -> .retries/<name>
    local old_dir base name dest
    for old_dir in "$CPBREW_META"/*_attempts(N); do
        [[ -d "$old_dir" ]] || continue
        base="$(basename "$old_dir")"
        name="${base%_attempts}"
        dest="$CPBREW_RETRIES/$name"
        $_MKDIR -p "$dest"
        find "$old_dir" -maxdepth 1 -type f -name "*.cpp" -exec mv {} "$dest/" \; 2>/dev/null
        rmdir "$old_dir" 2>/dev/null || true
    done

    # Backfill de repetición espaciada para problemas ya resueltos.
    local meta_file problem_name done_once intervals step attempts last_date next_date total
    for meta_file in "$CPBREW_META"/*.txt(N); do
        [[ -f "$meta_file" ]] || continue
        problem_name="$(basename "$meta_file" .txt)"
        done_once="$(_cb_meta_get "$problem_name" "done_once")"
        [[ "$done_once" != "1" ]] && continue
        intervals="$(_cb_meta_get "$problem_name" "sr_intervals")"
        [[ -z "$intervals" ]] && intervals="$CPBREW_SR_DEFAULT"

        step="$(_cb_meta_get "$problem_name" "sr_step")"
        if [[ -z "$step" || ! "$step" =~ ^[0-9]+$ ]]; then
            attempts="$(_cb_meta_get "$problem_name" "attempts")"
            [[ -z "$attempts" ]] && attempts=1
            step=$((attempts - 1))
            (( step < 0 )) && step=0
        fi
        total=$(_sr_count_intervals "$intervals")
        (( step > total )) && step=$total

        last_date="$(_cb_meta_get "$problem_name" "sr_last")"
        [[ -z "$last_date" || ! "$last_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && last_date="$(_sr_last_date_from_log "$problem_name")"
        [[ -z "$last_date" || ! "$last_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && last_date="$(_cb_meta_get "$problem_name" "creado")"
        [[ -z "$last_date" ]] && last_date="$(_today)"
        next_date="$(_sr_compute_next_date "$last_date" "$intervals" "$step")"

        _cb_meta_set "$problem_name" "sr_intervals" "$intervals"
        _cb_meta_set "$problem_name" "sr_step" "$step"
        _cb_meta_set "$problem_name" "sr_last" "$last_date"
        _cb_meta_set "$problem_name" "sr_next" "$next_date"
    done
}

_cb_personal_get_path() {
    local alias_key="$1"
    [[ -f "$CPBREW_PERSONAL" ]] || return 0
    awk -F'|' -v k="$alias_key" '
        {
            a=$1; p=$2;
            gsub(/^ +| +$/, "", a);
            gsub(/^ +| +$/, "", p);
            if (a == k) { print p; exit; }
        }
    ' "$CPBREW_PERSONAL"
}

_cb_personal_exists() {
    local alias_key="$1"
    [[ -n "$(_cb_personal_get_path "$alias_key")" ]]
}

_cb_personal_resolve_rel() {
    local raw="$1"
    if [[ "$raw" == /* ]]; then
        case "$raw" in
            "$CPBREW_ROOT"/*) echo "${raw#$CPBREW_ROOT/}" ;;
            "$CPBREW_ROOT") echo "" ;;
            *) return 1 ;;
        esac
    else
        echo "$raw"
    fi
}

_cb_personal_list_lines() {
    awk -F'|' '
        {
            a=$1; p=$2;
            gsub(/^ +| +$/, "", a);
            gsub(/^ +| +$/, "", p);
            if (a != "" && p != "") print a "|" p;
        }
    ' "$CPBREW_PERSONAL"
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
        printf "nombre=%s\ncreado=%s\nattempts=0\ndone_once=0\nsr_intervals=\nsr_step=0\nsr_last=\nsr_next=\nurl=\ngroup=\ndisplay_name=\n" \
            "$name" "$(_today)" > "$file"
    fi
}

_cb_normalize_problem_name() {
    local raw="$1"
    raw="${raw##*/}"
    raw="${raw%.cpp}"
    echo "$raw"
}

_cb_get_original_file() {
    local name="$1"
    local dest="$(_cb_meta_get "$name" "dest")"
    if [[ -n "$dest" && -f "$dest" ]]; then
        echo "$dest"
        return 0
    fi

    local from_log
    from_log=$(awk -F'|' -v n="$name" '
        {
            d=$1; nm=$2; t=$3; ref=$6;
            gsub(/^ +| +$/, "", nm);
            gsub(/^ +| +$/, "", t);
            gsub(/^ +| +$/, "", ref);
            if (nm == n && t == "NEW" && ref ~ /\.cpp$/) last=ref;
        }
        END { if (last != "") print last; }
    ' "$CPBREW_STATS/log")
    if [[ -n "$from_log" && -f "$from_log" ]]; then
        echo "$from_log"
        return 0
    fi

    local f
    for f in "$CPBREW_ROOT/CSES" "$CPBREW_ROOT/CODEFORCES" "$CPBREW_ROOT/ICPC"; do
        [[ -d "$f" ]] || continue
        local found=$(find "$f" -type f -name "${name}.cpp" 2>/dev/null | head -1)
        [[ -n "$found" ]] && echo "$found" && return 0
    done
    return 1
}

# ─── Attempts helpers ────────────────────────────────────────────────────────
_cb_attempts_dir() {
    echo "$CPBREW_RETRIES/${1}"
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
    printf "  ${G}%-32s${X} %s\n" "cpbrew"                   "Interfaz interactiva TUI (requiere fzf)"
    printf "  ${G}%-32s${X} %s\n" "cpbrew go <destino>"      "Abrir carpeta en VSCode"
    printf "  ${G}%-32s${X} %s\n" "cpbrew ls"                "Ver todos los destinos"
    echo ""
    _sep
    echo "  ${BOLD}SANDBOX — flujo principal${X}"
    _sep
    printf "  ${G}%-32s${X} %s\n" "cpbrew new <nombre>"      "Crear problema en sandbox"
    printf "  ${G}%-32s${X} %s\n" "cpbrew done"              "Guardar solución + registrar"
    printf "  ${G}%-32s${X} %s\n" "cpbrew retry"             "Borrar código y reintentar"
    printf "  ${G}%-32s${X} %s\n" "cpbrew retry-ls <p>"      "Listar retries de problema"
    printf "  ${G}%-32s${X} %s\n" "cpbrew retry-rm <p> <n>"  "Borrar retry específico"
    printf "  ${G}%-32s${X} %s\n" "cpbrew rm -a <p>"         "Borrar problema completo"
    printf "  ${G}%-32s${X} %s\n" "cpbrew mv <p> <dest>"     "Mover problema de carpeta"
    printf "  ${G}%-32s${X} %s\n" "cpbrew where <p>"         "Ver dónde está un problema"
    printf "  ${G}%-32s${X} %s\n" "cpbrew open <p>"          "Abrir URL del problema en browser"
    printf "  ${G}%-32s${X} %s\n" "cpbrew personal ..."      "Gestionar aliases personales"
    printf "  ${G}%-32s${X} %s\n" "cpbrew sr ..."            "Revisiones espaciadas (agenda)"
    printf "  ${G}%-32s${X} %s\n" "cpbrew sr skip <p> [+d]"  "Exentar o posponer repaso"
    printf "  ${G}%-32s${X} %s\n" "cpbrew sr clear-due"      "Marcar todos los vencidos como hechos"
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
    echo "  → Te pide plan de repetición espaciada (preset o custom)"
    echo ""
    echo "  ${BOLD}Retry (done_once=1):${X}"
    echo "  → NO copia a carpeta destino (ya existe)"
    echo "  → Guarda en attempts como attempt_N"
    echo "  → Avanza automáticamente al siguiente paso de SR"
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
    echo "  ${DIM}Orden: del más reciente al más antiguo.${X}"
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
    echo "  Ver attempts: ${C}cpbrew retry-ls <nombre>${X}"
    echo "  Para borrar un attempt: ${C}cpbrew retry-rm <nombre> <n>${X}"
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
    echo "  ${DIM}Filtros: find <txt>, -done, -pending(due SR), -retry, last <N>, --oneline${X}"
    echo "  ${DIM}En -pending aplica límite diario SR (${CPBREW_SR_REVIEW_CAP}) para no saturarte.${X}"
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
    echo "    ${G}cpbrew reset -f <folder>${X}  ${DIM}# borra una carpeta fija o personal + su log${X}"
    echo ""
    echo "  Ejemplos: ${C}cpbrew reset -f math${X}, ${C}cpbrew reset -f dp${X}"
    echo ""
}

_cb_help_sr() {
    echo ""
    echo "${BOLD}${C}  cpbrew sr${X} — Agenda de repetición espaciada"
    _sep
    echo "  ${BOLD}Uso:${X}"
    echo "    ${G}cpbrew sr list${X}                        ${DIM}# todas las próximas revisiones${X}"
    echo "    ${G}cpbrew sr first <N>${X}                   ${DIM}# próximas N revisiones${X}"
    echo "    ${G}cpbrew sr date <dd,mm,yyyy>${X}           ${DIM}# revisiones de una fecha${X}"
    echo "    ${G}cpbrew sr move <problema> <fecha>${X}     ${DIM}# mover revisión de un problema${X}"
    echo "    ${G}cpbrew sr shift <problema> <+/-dias>${X}  ${DIM}# adelantar/posponer por días${X}"
    echo "    ${G}cpbrew sr move-date <f1> <f2>${X}         ${DIM}# mover todas las revisiones de f1 a f2${X}"
    echo "    ${G}cpbrew sr skip <problema>${X}             ${DIM}# exentar repaso (marcar como completado)${X}"
    echo "    ${G}cpbrew sr skip <problema> <+/-dias>${X}   ${DIM}# posponer repaso N días${X}"
    echo "    ${G}cpbrew sr clear-due${X}                   ${DIM}# marcar todos los vencidos como completados${X}"
    echo ""
}

_cb_help_personal() {
    echo ""
    echo "${BOLD}${C}  cpbrew personal${X} — Carpetas personales con alias"
    _sep
    echo "  ${BOLD}Uso:${X}"
    echo "    ${G}cpbrew personal add <alias> <ruta>${X}   ${DIM}# crea carpeta y la registra${X}"
    echo "    ${G}cpbrew personal rm <alias>${X}           ${DIM}# borra carpeta personal y su contenido${X}"
    echo "    ${G}cpbrew personal ls${X}                   ${DIM}# lista aliases personales${X}"
    echo ""
    echo "  ${DIM}La ruta debe estar dentro del repo. Puede ser relativa o absoluta dentro de ${CPBREW_ROOT}.${X}"
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
        *)
            local personal_path="$(_cb_personal_get_path "$key")"
            [[ -n "$personal_path" ]] && echo "$personal_path" || return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# GO
# ═══════════════════════════════════════════════════════════════════

_cb_go() {
    [[ "$1" == "help" ]] && _cb_help_go && return
    _cb_init
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

_cb_personal() {
    _cb_init
    local sub="$1"
    shift
    [[ -z "$sub" || "$sub" == "help" ]] && _cb_help_personal && return

    case "$sub" in
        add)
            local alias_key="$1"
            local raw_path="$2"
            [[ -z "$alias_key" || -z "$raw_path" ]] && _err "Uso: cpbrew personal add <alias> <ruta>" && return 1
            [[ ! "$alias_key" =~ ^[A-Za-z0-9_-]+$ ]] && _err "Alias inválido. Usa letras, números, _ o -." && return 1

            if _cb_dest_path_from_key "$alias_key" >/dev/null 2>&1; then
                _err "Alias ya ocupado: $alias_key"
                return 1
            fi

            local rel_path="$(_cb_personal_resolve_rel "$raw_path")"
            [[ $? -ne 0 ]] && _err "La ruta debe estar dentro del repo." && return 1
            [[ -z "$rel_path" ]] && _err "No puedes registrar la raíz del repo como carpeta personal." && return 1

            local fullpath="$CPBREW_ROOT/$rel_path"
            $_MKDIR -p "$fullpath"
            echo "${alias_key}|${rel_path}" >> "$CPBREW_PERSONAL"
            _ok "Personal agregado: ${BOLD}$alias_key${X} → ${DIM}$rel_path${X}"
            ;;

        rm)
            local alias_key="$1"
            [[ -z "$alias_key" ]] && _err "Uso: cpbrew personal rm <alias>" && return 1
            local rel_path="$(_cb_personal_get_path "$alias_key")"
            [[ -z "$rel_path" ]] && _err "Alias personal no encontrado: $alias_key" && return 1
            local fullpath="$CPBREW_ROOT/$rel_path"

            echo ""
            _warn "Borrará la carpeta personal ${BOLD}$alias_key${X} y todo su contenido."
            echo "  ${DIM}$fullpath${X}"
            echo -n "  ¿Confirmar? [y/N]: "
            read confirm
            [[ "$confirm" != "y" && "$confirm" != "Y" ]] && echo "  Cancelado." && echo "" && return

            rm -rf "$fullpath"
            awk -F'|' -v k="$alias_key" '
                {
                    a=$1;
                    gsub(/^ +| +$/, "", a);
                    if (a != k) print $0;
                }
            ' "$CPBREW_PERSONAL" > "$CPBREW_PERSONAL.tmp.$$"
            mv "$CPBREW_PERSONAL.tmp.$$" "$CPBREW_PERSONAL"
            _ok "Personal eliminado: ${BOLD}$alias_key${X}"
            echo ""
            ;;

        ls)
            _cb_ls
            ;;

        *)
            _err "Subcomando personal no reconocido. Usa ${C}cpbrew personal help${X}."
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# LS
# ═══════════════════════════════════════════════════════════════════

_cb_ls() {
    _cb_init
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
    echo "${BOLD}  ── PERSONAL ──────────────────────────────────────${X}"
    local -a personal_rows
    local prow
    while IFS= read -r prow; do
        [[ -n "$prow" ]] && personal_rows+=("$prow")
    done < <(_cb_personal_list_lines)
    if [[ ${#personal_rows[@]} -eq 0 ]]; then
        echo "  ${DIM}Vacío. Usa ${C}cpbrew personal add <alias> <ruta>${X}${DIM}.${X}"
    else
        local idx=1
        while (( idx <= ${#personal_rows[@]} )); do
            local left_alias="${personal_rows[$idx]%%|*}"
            local left_path="${personal_rows[$idx]#*|}"
            local right_alias="" right_path=""
            if (( idx + 1 <= ${#personal_rows[@]} )); then
                right_alias="${personal_rows[$((idx + 1))]%%|*}"
                right_path="${personal_rows[$((idx + 1))]#*|}"
            fi
            printf "  ${Y}%-10s${X} ${DIM}%-28s${X}" "$left_alias" "$left_path"
            if [[ -n "$right_alias" ]]; then
                printf "  ${Y}%-10s${X} ${DIM}%s${X}" "$right_alias" "$right_path"
            fi
            echo ""
            idx=$((idx + 2))
        done
    fi
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
    local today=$(_today)

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

    # ── Leer datos CPH si están disponibles ─────────────────────
    _cb_cph_read_prob "$name"
    local cph_url="$(_cb_meta_get "$name" "url")"
    local cph_group="$(_cb_meta_get "$name" "group")"
    local cph_display="$(_cb_meta_get "$name" "display_name")"
    if [[ -n "$cph_display" ]]; then
        echo "  ${C}${BOLD}$cph_display${X}"
    fi
    if [[ -n "$cph_url" ]]; then
        echo "  ${DIM}$cph_url${X}"
    fi

    local done_once=$(_cb_meta_get "$name" "done_once")
    [[ -z "$done_once" ]] && done_once=0

    # ── Guardar attempt ──────────────────────────────────────────
    local attempt_file=$(_cb_save_attempt "$name")
    local attempt_n=$(_cb_meta_get "$name" "attempts")
    _ok "Attempt #${attempt_n} guardado"
    echo "  ${DIM}→ $attempt_file${X}"

    # ── Si es primera vez: copiar a carpeta destino ──────────────
    if [[ "$done_once" == "0" ]]; then
        local auto_dest="$(_cb_cph_auto_dest "$cph_group")"
        local default_dest="${auto_dest:-math}"
        echo ""
        echo "  ${BOLD}Primera solución — ¿dónde guardar?${X}"
        if [[ -n "$auto_dest" ]]; then
            echo "  ${DIM}Auto-detectado: ${X}${BOLD}$auto_dest${X}${DIM} (${cph_group})${X}"
        fi
        echo "  ${DIM}Destinos: math, cf, dp, graph, sort, etc. + tus aliases personales${X}"
        echo -n "  Destino (Enter = ${BOLD}${default_dest}${X}): "
        read dest_key
        [[ -z "$dest_key" ]] && dest_key="$default_dest"

        local dest_path="$(_cb_dest_path_from_key "$dest_key")"
        if [[ $? -ne 0 ]]; then
            [[ "$dest_key" == /* ]] && _err "Usa alias o ruta relativa al repo." && return 1
            dest_path="$dest_key"
        fi

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

        echo ""
        echo "  ${BOLD}Repetición espaciada (SR)${X}"
        echo "  ${DIM}Piensa en 5 nuevos/día: usa un plan que no te sature.${X}"
        echo "  ${G}1${X}) Light ${DIM}(3,7,14,30)${X} ${DIM}[recomendado]${X}"
        echo "  ${Y}2${X}) Medium ${DIM}(1,3,7,14,30)${X}"
        echo "  ${C}3${X}) Aggressive ${DIM}(1,2,4,7,14)${X}"
        echo "  ${M}4${X}) Custom ${DIM}(ej: 1,3,7,10)${X}"
        echo -n "  Plan SR (Enter = 1): "
        read sopt
        [[ -z "$sopt" ]] && sopt=1

        local sr_intervals
        case "$sopt" in
            1) sr_intervals="3,7,14,30" ;;
            2) sr_intervals="1,3,7,14,30" ;;
            3) sr_intervals="1,2,4,7,14" ;;
            4)
                echo -n "  Intervals custom: "
                read sr_intervals
                sr_intervals=$(echo "$sr_intervals" | $_SED 's/ //g')
                [[ ! "$sr_intervals" =~ ^[0-9]+(,[0-9]+)*$ ]] && _warn "Formato inválido. Uso default 3,7,14,30." && sr_intervals="3,7,14,30"
                ;;
            *)
                sr_intervals="3,7,14,30"
                ;;
        esac
        local sr_next="$(_sr_compute_next_date "$today" "$sr_intervals" 0)"
        _cb_meta_set "$name" "sr_intervals" "$sr_intervals"
        _cb_meta_set "$name" "sr_step" "0"
        _cb_meta_set "$name" "sr_last" "$today"
        _cb_meta_set "$name" "sr_next" "$sr_next"
        echo "  ${DIM}SR: $sr_intervals · próximo repaso: $sr_next${X}"
    else
        echo ""
        echo "  ${Y}↺${X} Retry — código guardado solo en historial de attempts."
        local dest_file=$(_cb_meta_get "$name" "dest")
        if [[ -n "$dest_file" ]]; then
            echo "  ${DIM}Solución original en: $dest_file${X}"
        fi

        local sr_intervals="$(_cb_meta_get "$name" "sr_intervals")"
        [[ -z "$sr_intervals" ]] && sr_intervals="$CPBREW_SR_DEFAULT"
        local sr_step="$(_cb_meta_get "$name" "sr_step")"
        [[ -z "$sr_step" ]] && sr_step=0
        local sr_total="$(_sr_count_intervals "$sr_intervals")"
        if (( sr_step < sr_total )); then
            sr_step=$((sr_step + 1))
            local sr_next="$(_sr_compute_next_date "$today" "$sr_intervals" "$sr_step")"
            _cb_meta_set "$name" "sr_intervals" "$sr_intervals"
            _cb_meta_set "$name" "sr_step" "$sr_step"
            _cb_meta_set "$name" "sr_last" "$today"
            _cb_meta_set "$name" "sr_next" "$sr_next"
            echo "  ${DIM}SR actualizado · paso $sr_step/$sr_total · siguiente: $sr_next${X}"
        else
            _cb_meta_set "$name" "sr_next" "done"
            echo "  ${DIM}SR completado para este problema.${X}"
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

_cb_retry_ls() {
    _cb_init
    local name="$1"
    if [[ -z "$name" ]]; then
        local detected=$(_cb_detect_active)
        [[ -n "$detected" ]] && name="$detected"
    fi
    if [[ -z "$name" ]]; then
        _err "Uso: cpbrew retry-ls <problema>"
        return 1
    fi

    local dir="$(_cb_attempts_dir "$name")"
    local files=("$dir"/${name}_attempt_*.cpp(N))
    if (( ${#files[@]} == 0 )); then
        _warn "No hay retries para ${BOLD}$name${X}."
        return 1
    fi

    echo ""
    echo "  ${BOLD}${C}retries${X} ${DIM}($name)${X}"
    local f bn n
    for f in "${files[@]}"; do
        bn="$(basename "$f")"
        n="${bn##*_attempt_}"
        n="${n%.cpp}"
        printf "  ${Y}%3s${X}  ${DIM}%s${X}  ${DIM}%s${X}\n" "$n" "$(date -r "$f" "+%Y-%m-%d %H:%M")" "$f"
    done
    echo ""
}

_cb_retry_rm() {
    [[ "$1" == "help" ]] && echo "Uso: cpbrew retry-rm <problema> <attempt_n>" && return
    _cb_init

    local name="$1"
    local num="$2"
    if [[ -z "$name" || -z "$num" || ! "$num" =~ ^[0-9]+$ ]]; then
        _err "Uso: cpbrew retry-rm <problema> <attempt_n>"
        return 1
    fi

    local dir="$(_cb_attempts_dir "$name")"
    local file="$dir/${name}_attempt_${num}.cpp"
    if [[ ! -f "$file" ]]; then
        _err "No existe: $file"
        return 1
    fi

    rm -f "$file"

    local tmp="$CPBREW_STATS/log.tmp.$$"
    : > "$tmp"
    local line
    while IFS= read -r line; do
        local f1 f2 f3 f4 f5 f6 n t a
        IFS='|' read -r f1 f2 f3 f4 f5 f6 <<< "$line"
        n=$(echo "$f2" | $_SED 's/^ *//;s/ *$//')
        t=$(echo "$f3" | $_SED 's/^ *//;s/ *$//')
        a=$(echo "$f4" | $_SED 's/^ *//;s/ *$//')
        if [[ "$n" == "$name" && "$t" == "RETRY" && "$a" == "attempt_${num}" ]]; then
            continue
        fi
        echo "$line" >> "$tmp"
    done < "$CPBREW_STATS/log"
    mv "$tmp" "$CPBREW_STATS/log"

    local max_attempt=0
    local f bn n
    for f in "$dir"/${name}_attempt_*.cpp(N); do
        bn="$(basename "$f")"
        n="${bn##*_attempt_}"
        n="${n%.cpp}"
        [[ "$n" =~ ^[0-9]+$ ]] && (( n > max_attempt )) && max_attempt="$n"
    done
    _cb_meta_set "$name" "attempts" "$max_attempt"
    _cb_rebuild_stats_from_log

    _ok "Retry eliminado: ${BOLD}${name}_attempt_${num}.cpp${X}"
}

_cb_rm_problem() {
    _cb_init
    [[ "$1" == "help" ]] && echo "Uso: cpbrew rm -a <problema|archivo.cpp>" && return
    if [[ "$1" != "-a" || -z "$2" ]]; then
        _err "Uso: cpbrew rm -a <problema|archivo.cpp>"
        return 1
    fi

    local name="$(_cb_normalize_problem_name "$2")"
    [[ -z "$name" ]] && _err "Nombre inválido." && return 1

    echo ""
    _warn "Se borrará TODO de ${BOLD}$name${X} (original, retries, sandbox y log)."
    echo -n "  ¿Confirmar? [y/N]: "
    read c
    [[ "$c" != "y" && "$c" != "Y" ]] && echo "  Cancelado." && echo "" && return

    local original="$(_cb_get_original_file "$name")"
    [[ -n "$original" && -f "$original" ]] && rm -f "$original"
    rm -f "$CPBREW_SANDBOX/${name}.cpp" "$CPBREW_META/${name}.txt"
    rm -rf "$CPBREW_RETRIES/${name}" "$CPBREW_META/${name}_attempts"

    local tmp="$CPBREW_STATS/log.tmp.$$"
    : > "$tmp"
    local line
    while IFS= read -r line; do
        local f1 f2 f3 f4 f5 f6 n
        IFS='|' read -r f1 f2 f3 f4 f5 f6 <<< "$line"
        n=$(echo "$f2" | $_SED 's/^ *//;s/ *$//')
        [[ "$n" == "$name" ]] && continue
        echo "$line" >> "$tmp"
    done < "$CPBREW_STATS/log"
    mv "$tmp" "$CPBREW_STATS/log"
    _cb_rebuild_stats_from_log

    _ok "Problema eliminado por completo: ${BOLD}$name${X}"
    echo ""
}

_cb_move_problem() {
    _cb_init
    [[ "$1" == "help" ]] && echo "Uso: cpbrew mv <problema|archivo.cpp> <destino>" && return
    [[ -z "$1" || -z "$2" ]] && _err "Uso: cpbrew mv <problema|archivo.cpp> <destino>" && return 1

    local name="$(_cb_normalize_problem_name "$1")"
    local dest_key="$2"
    local rel="$(_cb_dest_path_from_key "$dest_key")"
    if [[ $? -ne 0 ]]; then
        [[ "$dest_key" == /* ]] && _err "Usa alias o ruta relativa al repo." && return 1
        [[ -d "$CPBREW_ROOT/$dest_key" ]] && rel="$dest_key" || rel="$dest_key"
    fi

    local original="$(_cb_get_original_file "$name")"
    if [[ -z "$original" || ! -f "$original" ]]; then
        _err "No encontré el archivo original de ${BOLD}$name${X}."
        return 1
    fi

    local dest_dir="$CPBREW_ROOT/$rel"
    $_MKDIR -p "$dest_dir"
    local new_file="$dest_dir/${name}.cpp"
    if [[ "$original" != "$new_file" ]]; then
        mv "$original" "$new_file"
    fi
    _cb_meta_set "$name" "dest" "$new_file"

    local tmp="$CPBREW_STATS/log.tmp.$$"
    : > "$tmp"
    local line
    while IFS= read -r line; do
        local f1 f2 f3 f4 f5 f6 n t
        IFS='|' read -r f1 f2 f3 f4 f5 f6 <<< "$line"
        n=$(echo "$f2" | $_SED 's/^ *//;s/ *$//')
        t=$(echo "$f3" | $_SED 's/^ *//;s/ *$//')
        if [[ "$n" == "$name" && "$t" == "NEW" ]]; then
            local d a r
            d=$(echo "$f1" | $_SED 's/^ *//;s/ *$//')
            a=$(echo "$f4" | $_SED 's/^ *//;s/ *$//')
            r=$(echo "$f5" | $_SED 's/^ *//;s/ *$//')
            echo "$d | $name | NEW | $a | $r | $new_file" >> "$tmp"
        else
            echo "$line" >> "$tmp"
        fi
    done < "$CPBREW_STATS/log"
    mv "$tmp" "$CPBREW_STATS/log"

    _ok "Movido ${BOLD}$name${X} → ${DIM}$new_file${X}"
}

_cb_where_problem() {
    _cb_init
    [[ -z "$1" || "$1" == "help" ]] && echo "Uso: cpbrew where <problema|archivo.cpp>" && return
    local name="$(_cb_normalize_problem_name "$1")"
    _cb_cph_read_prob "$name" 2>/dev/null

    local sb="$CPBREW_SANDBOX/${name}.cpp"
    local original="$(_cb_get_original_file "$name")"
    local rdir="$CPBREW_RETRIES/${name}"
    local retries=0
    local sr_intervals="$(_cb_meta_get "$name" "sr_intervals")"
    local sr_step="$(_cb_meta_get "$name" "sr_step")"
    local sr_next="$(_cb_meta_get "$name" "sr_next")"
    local sr_last="$(_cb_meta_get "$name" "sr_last")"
    local url="$(_cb_meta_get "$name" "url")"
    local display_name="$(_cb_meta_get "$name" "display_name")"
    local group="$(_cb_meta_get "$name" "group")"
    [[ -d "$rdir" ]] && retries=$(find "$rdir" -maxdepth 1 -type f -name "${name}_attempt_*.cpp" | wc -l | tr -d ' ')
    [[ -z "$sr_intervals" ]] && sr_intervals="(sin configurar)"
    [[ -z "$sr_step" ]] && sr_step="0"
    [[ -z "$sr_next" ]] && sr_next="(sin fecha)"
    [[ -z "$sr_last" ]] && sr_last="(sin registro)"

    echo ""
    echo "  ${BOLD}${C}$name${X}"
    [[ -n "$display_name" ]] && echo "  ${G}nombre:${X} ${BOLD}$display_name${X}"
    [[ -n "$group" ]] && echo "  ${G}grupo:${X} ${DIM}$group${X}"
    [[ -n "$url" ]] && echo "  ${G}url:${X} ${C}$url${X}"
    [[ -f "$sb" ]] && echo "  ${G}sandbox:${X} ${DIM}$sb${X}" || echo "  ${DIM}sandbox: no${X}"
    [[ -n "$original" && -f "$original" ]] && echo "  ${G}original:${X} ${DIM}$original${X}" || echo "  ${DIM}original: no${X}"
    echo "  ${G}retries:${X} ${BOLD}$retries${X} ${DIM}($rdir)${X}"
    echo "  ${G}sr:${X} ${DIM}$sr_intervals${X} ${DIM}(step:$sr_step · last:$sr_last · next:$sr_next)${X}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
# OPEN — abrir URL del problema en el navegador
# ═══════════════════════════════════════════════════════════════════

_cb_open_url() {
    _cb_init
    [[ -z "$1" || "$1" == "help" ]] && echo "Uso: cpbrew open <problema>" && return
    local name="$(_cb_normalize_problem_name "$1")"
    _cb_cph_read_prob "$name" 2>/dev/null
    local url="$(_cb_meta_get "$name" "url")"
    if [[ -z "$url" ]]; then
        _err "No hay URL para ${BOLD}$name${X}. Asegúrate de haber abierto el problema con CPH."
        return 1
    fi
    open "$url"
    _ok "Abriendo: ${C}$url${X}"
}

_cb_parse_user_date() {
    local raw="$1"
    local ymd=""
    if [[ "$raw" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        ymd="$raw"
    elif [[ "$raw" =~ ^[0-9]{2}[,/-][0-9]{2}[,/-][0-9]{4}$ ]]; then
        local clean="${raw//\//,}"
        clean="${clean//-/,}"
        local dd="${clean%%,*}"
        local rest="${clean#*,}"
        local mm="${rest%%,*}"
        local yyyy="${rest##*,}"
        ymd="${yyyy}-${mm}-${dd}"
    else
        echo ""
        return 1
    fi
    local valid=$($_DATE -j -f "%Y-%m-%d" "$ymd" "+%Y-%m-%d" 2>/dev/null)
    [[ -z "$valid" ]] && echo "" && return 1
    echo "$valid"
}

_cb_sr_rows_sorted() {
    local meta_file name done next step intervals
    for meta_file in "$CPBREW_META"/*.txt(N); do
        [[ -f "$meta_file" ]] || continue
        name="$(basename "$meta_file" .txt)"
        done="$(_cb_meta_get "$name" "done_once")"
        [[ "$done" != "1" ]] && continue
        next="$(_cb_meta_get "$name" "sr_next")"
        [[ -z "$next" || "$next" == "done" ]] && continue
        [[ ! "$next" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && continue
        step="$(_cb_meta_get "$name" "sr_step")"
        intervals="$(_cb_meta_get "$name" "sr_intervals")"
        echo "$next|$name|$step|$intervals"
    done | sort
}

_cb_sr_print_rows() {
    local rows="$1"
    local count=0
    local line
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local d n s i
        IFS='|' read -r d n s i <<< "$line"
        printf "  ${Y}%-12s${X}  ${BOLD}%-28s${X}  ${DIM}step:%s · %s${X}\n" "$d" "$n" "$s" "$i"
        count=$((count + 1))
    done <<< "$rows"
    [[ $count -eq 0 ]] && echo "  ${DIM}Sin revisiones en ese filtro.${X}"
}

_cb_sr() {
    emulate -L zsh
    setopt noxtrace noverbose typesetsilent
    set +x +v 2>/dev/null
    _cb_init
    local sub="$1"
    shift
    [[ -z "$sub" || "$sub" == "help" ]] && _cb_help_sr && return

    case "$sub" in
        list)
            echo ""
            echo "${BOLD}${C}  ☕  Próximas revisiones${X}"
            _sep
            _cb_sr_print_rows "$(_cb_sr_rows_sorted)"
            echo ""
            ;;

        first)
            [[ -z "$1" || ! "$1" =~ ^[0-9]+$ ]] && _err "Usa: cpbrew sr first <N>" && return 1
            local n="$1"
            local rows="$(_cb_sr_rows_sorted | head -n "$n")"
            echo ""
            echo "${BOLD}${C}  ☕  Próximas $n revisiones${X}"
            _sep
            _cb_sr_print_rows "$rows"
            echo ""
            ;;

        date)
            [[ -z "$1" ]] && _err "Usa: cpbrew sr date <dd,mm,yyyy>" && return 1
            local date_ymd="$(_cb_parse_user_date "$1")"
            [[ -z "$date_ymd" ]] && _err "Fecha inválida. Usa dd,mm,yyyy." && return 1
            local rows="$(_cb_sr_rows_sorted | awk -F'|' -v d="$date_ymd" '$1 == d')"
            echo ""
            echo "${BOLD}${C}  ☕  Revisiones del ${date_ymd}${X}"
            _sep
            _cb_sr_print_rows "$rows"
            echo ""
            ;;

        move)
            [[ -z "$1" || -z "$2" ]] && _err "Usa: cpbrew sr move <problema> <dd,mm,yyyy>" && return 1
            local name="$(_cb_normalize_problem_name "$1")"
            local date_ymd="$(_cb_parse_user_date "$2")"
            [[ -z "$date_ymd" ]] && _err "Fecha inválida. Usa dd,mm,yyyy." && return 1
            [[ ! -f "$CPBREW_META/${name}.txt" ]] && _err "No existe problema: $name" && return 1
            _cb_meta_set "$name" "sr_next" "$date_ymd"
            _ok "Revisión movida: ${BOLD}$name${X} → ${BOLD}$date_ymd${X}"
            ;;

        shift)
            [[ -z "$1" || -z "$2" ]] && _err "Usa: cpbrew sr shift <problema> <+/-dias>" && return 1
            local name="$(_cb_normalize_problem_name "$1")"
            local delta="$2"
            [[ ! "$delta" =~ ^[+-]?[0-9]+$ ]] && _err "Días inválidos. Ej: -2, +3, 5" && return 1
            local curr="$(_cb_meta_get "$name" "sr_next")"
            [[ -z "$curr" || "$curr" == "done" || ! "$curr" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && _err "No hay sr_next válida para $name" && return 1
            local new_date=$($_DATE -j -v"${delta}"d -f "%Y-%m-%d" "$curr" "+%Y-%m-%d" 2>/dev/null)
            [[ -z "$new_date" ]] && _err "No pude calcular la nueva fecha." && return 1
            _cb_meta_set "$name" "sr_next" "$new_date"
            _ok "Revisión movida: ${BOLD}$name${X} ${DIM}($curr -> $new_date)${X}"
            ;;

        skip)
            [[ -z "$1" ]] && _err "Usa: cpbrew sr skip <problema> [+/-dias]" && return 1
            local name="$(_cb_normalize_problem_name "$1")"
            [[ ! -f "$CPBREW_META/${name}.txt" ]] && _err "No existe problema: $name" && return 1
            if [[ -n "$2" ]]; then
                local delta="$2"
                [[ ! "$delta" =~ ^[+-]?[0-9]+$ ]] && _err "Días inválidos. Ej: +7, -3, 14" && return 1
                local curr="$(_cb_meta_get "$name" "sr_next")"
                local base_date="$curr"
                [[ -z "$base_date" || "$base_date" == "done" || ! "$base_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && base_date="$(_today)"
                local new_date=$($_DATE -j -v"${delta}"d -f "%Y-%m-%d" "$base_date" "+%Y-%m-%d" 2>/dev/null)
                [[ -z "$new_date" ]] && _err "No pude calcular la nueva fecha." && return 1
                _cb_meta_set "$name" "sr_next" "$new_date"
                _ok "Repaso pospuesto: ${BOLD}$name${X} → ${BOLD}$new_date${X}"
            else
                _cb_meta_set "$name" "sr_next" "done"
                _ok "Repaso exentado: ${BOLD}$name${X} ${DIM}(marcado como completado)${X}"
            fi
            ;;

        clear-due)
            local today_cdue="$(_today)"
            local mf name_cdue next_cdue cleared=0
            for mf in "$CPBREW_META"/*.txt(N); do
                [[ -f "$mf" ]] || continue
                name_cdue="$(basename "$mf" .txt)"
                next_cdue="$(_cb_meta_get "$name_cdue" "sr_next")"
                [[ -z "$next_cdue" || "$next_cdue" == "done" ]] && continue
                [[ ! "$next_cdue" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && continue
                if [[ "$next_cdue" < "$today_cdue" || "$next_cdue" == "$today_cdue" ]]; then
                    _cb_meta_set "$name_cdue" "sr_next" "done"
                    cleared=$((cleared + 1))
                fi
            done
            _ok "${BOLD}$cleared${X} problemas vencidos marcados como completados."
            ;;

        move-date)
            [[ -z "$1" || -z "$2" ]] && _err "Usa: cpbrew sr move-date <dd,mm,yyyy> <dd,mm,yyyy>" && return 1
            local from="$(_cb_parse_user_date "$1")"
            local to="$(_cb_parse_user_date "$2")"
            [[ -z "$from" || -z "$to" ]] && _err "Fechas inválidas. Usa dd,mm,yyyy." && return 1
            local mf name next moved=0
            for mf in "$CPBREW_META"/*.txt(N); do
                [[ -f "$mf" ]] || continue
                name="$(basename "$mf" .txt)"
                next="$(_cb_meta_get "$name" "sr_next")"
                if [[ "$next" == "$from" ]]; then
                    _cb_meta_set "$name" "sr_next" "$to"
                    moved=$((moved + 1))
                fi
            done
            _ok "Revisiones movidas de ${BOLD}$from${X} a ${BOLD}$to${X}: ${BOLD}$moved${X}"
            ;;

        *)
            _err "Subcomando SR no reconocido. Usa ${C}cpbrew sr help${X}."
            return 1
            ;;
    esac
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
            local today=$(_today)
            local done_filter="all"
            local retry_only=0
            local one_line=0
            local limit=0
            local query=""
            local token
            while (( $# > 0 )); do
                token="$1"
                case "$token" in
                    find)
                        shift
                        [[ $# -eq 0 ]] && _err "Usa: cpbrew sb ls find <texto>" && return 1
                        while (( $# > 0 )); do
                            case "$1" in
                                find|-done|-pending|-retry|last|--oneline|-oneline|oneline|help) break ;;
                                *) [[ -n "$query" ]] && query+=" "; query+="$1"; shift ;;
                            esac
                        done
                        ;;
                    -done) done_filter="done"; shift ;;
                    -pending) done_filter="pending"; shift ;;
                    -retry) retry_only=1; shift ;;
                    --oneline|-oneline|oneline) one_line=1; shift ;;
                    last)
                        shift
                        [[ $# -eq 0 || ! "$1" =~ ^[0-9]+$ ]] && _err "Usa: cpbrew sb ls last <N>" && return 1
                        limit="$1"
                        shift
                        ;;
                    help)
                        _cb_help_sb
                        return
                        ;;
                    *)
                        _err "Filtro no reconocido en sb ls: $token"
                        echo "  Usa: cpbrew sb ls [find <txt>] [-done|-pending] [-retry] [last N] [--oneline]"
                        return 1
                        ;;
                esac
            done

            local files=($(ls -t "$CPBREW_SANDBOX"/*.cpp 2>/dev/null))
            if [[ ${#files[@]} -eq 0 ]]; then
                echo "  ${DIM}Vacío. Usa ${C}cpbrew new <nombre>${DIM}.${X}"
            else
                local shown=0
                local hidden_due=0
                local effective_limit="$limit"
                if [[ "$done_filter" == "pending" && "$effective_limit" -eq 0 ]]; then
                    effective_limit="$CPBREW_SR_REVIEW_CAP"
                fi
                (( one_line == 0 )) && printf "  ${BOLD}%-28s  %-8s  %-8s  %s${X}\n" "Problema" "Attempts" "1ª vez" "Guardado en" && _sep
                for f in $files; do
                    local n=$(basename "$f" .cpp)
                    local attempts=$(_cb_meta_get "$n" "attempts")
                    [[ -z "$attempts" ]] && attempts=0
                    local done_once=$(_cb_meta_get "$n" "done_once")
                    [[ -z "$done_once" ]] && done_once=0
                    local dest=$(_cb_meta_get "$n" "dest")
                    [[ -z "$dest" ]] && dest="${DIM}pendiente${X}"
                    local sr_next=$(_cb_meta_get "$n" "sr_next")
                    local is_due=0
                    if [[ "$done_once" == "1" && -n "$sr_next" && "$sr_next" != "done" && ( "$sr_next" < "$today" || "$sr_next" == "$today" ) ]]; then
                        is_due=1
                    fi

                    if [[ "$done_filter" == "done" && "$done_once" != "1" ]]; then
                        continue
                    fi
                    if [[ "$done_filter" == "pending" && "$is_due" != "1" ]]; then
                        continue
                    fi
                    if (( retry_only == 1 && attempts < 2 )); then
                        continue
                    fi
                    if [[ -n "$query" ]]; then
                        local haystack="$(echo "$n $dest" | tr '[:upper:]' '[:lower:]')"
                        local needle="$(echo "$query" | tr '[:upper:]' '[:lower:]')"
                        [[ "$haystack" != *"$needle"* ]] && continue
                    fi

                    local done_str="${R}no${X}"
                    [[ "$done_once" == "1" ]] && done_str="${G}sí${X}"
                    if (( effective_limit > 0 && shown >= effective_limit )); then
                        [[ "$done_filter" == "pending" ]] && hidden_due=$((hidden_due + 1))
                        continue
                    fi
                    if (( one_line == 1 )); then
                        local due_tag=""
                        (( is_due == 1 )) && due_tag=" · ${Y}due:${sr_next}${X}"
                        printf "  ${Y}%s${X}  ${DIM}(a:%s · done:%b%s)${X}\n" "$n" "$attempts" "$done_str" "$due_tag"
                    else
                        printf "  ${Y}%-28s${X}  ${G}%-8s${X}  " "$n" "$attempts"
                        echo -n "$done_str"
                        if (( is_due == 1 )); then
                            printf "  ${DIM}%s${X} ${Y}[due %s]${X}\n" "$dest" "$sr_next"
                        else
                            printf "  ${DIM}%s${X}\n" "$dest"
                        fi
                    fi
                    shown=$((shown + 1))
                done
                if (( shown == 0 )); then
                    echo "  ${DIM}Sin resultados para esos filtros.${X}"
                fi
                if (( hidden_due > 0 )); then
                    echo "  ${DIM}+${hidden_due} due ocultos por límite SR (${CPBREW_SR_REVIEW_CAP}/día). Usa ${C}last${X}${DIM} si quieres ver más.${X}"
                fi
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
                            _cb_cph_read_prob "$fname"
                            local _prob_url=$(_cb_meta_get "$fname" "url")
                            local _prob_group=$(_cb_meta_get "$fname" "group")
                            local _log_extra=""
                            [[ -n "$_prob_group" ]] && _log_extra=" · $_prob_group"
                            [[ -n "$_prob_url" ]] && _log_extra="$_log_extra · $_prob_url"
                            echo "[$(date '+%H:%M:%S')] CPH: $fname → sandbox${_log_extra}" >> "$logfile"
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

        # Mostrar del más reciente al más antiguo.
        local -a reversed_rows
        local idx
        for (( idx=${#rows[@]}; idx>=1; idx-- )); do
            reversed_rows+=("${rows[$idx]}")
        done
        rows=("${reversed_rows[@]}")

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
            for d in "$CPBREW_ROOT/CSES" "$CPBREW_ROOT/CODEFORCES" "$CPBREW_ROOT/ICPC" "$CPBREW_SANDBOX" "$CPBREW_RETRIES"; do
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

            find "$CPBREW_RETRIES" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} + 2>/dev/null
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
            local rel_status=$?
            local is_personal=0
            _cb_personal_exists "$folder" && is_personal=1
            if [[ $rel_status -ne 0 ]]; then
                [[ "$folder" == /* ]] && _err "Usa ruta relativa o alias de cpbrew ls." && return 1
                [[ -d "$CPBREW_ROOT/$folder" ]] && rel="$folder" || { _err "Carpeta no válida: $folder"; return 1; }
            fi

            local abs="$CPBREW_ROOT/$rel"
            [[ ! -d "$abs" ]] && _err "No existe: $abs" && return 1
            if [[ "$abs" == "$CPBREW_SANDBOX" || "$abs" == "$CPBREW_ROOT" ]]; then
                _err "Para sandbox o root usa reset -a."
                return 1
            fi
            if [[ "$is_personal" != "1" && "$rel" != CSES/* && "$rel" != CODEFORCES* && "$rel" != ICPC/* ]]; then
                _err "Solo puedes resetear carpetas fijas o aliases personales registrados."
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
                rm -rf "$CPBREW_META/${n}_attempts" "$CPBREW_RETRIES/${n}"
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
            if [[ "$is_personal" == "1" ]]; then
                awk -F'|' -v k="$folder" '
                    {
                        a=$1;
                        gsub(/^ +| +$/, "", a);
                        if (a != k) print $0;
                    }
                ' "$CPBREW_PERSONAL" > "$CPBREW_PERSONAL.tmp.$$"
                mv "$CPBREW_PERSONAL.tmp.$$" "$CPBREW_PERSONAL"
            fi
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
# TUI — Interfaz interactiva (requiere fzf)
# ═══════════════════════════════════════════════════════════════════

_cb_has_fzf() { command -v fzf >/dev/null 2>&1; }

# Tema unificado
_TUI_THEME="--color=fg:#808080,bg:-1,fg+:#e8e8e8,bg+:#1a1a1a,gutter:-1,hl:#5f87d7,hl+:#87afff,info:#444444,border:#2a2a2a,prompt:#5f87d7,pointer:#e06c75,marker:#5f87d7,header:#4a4a4a,preview-bg:-1,preview-fg:#9a9a9a"
_TUI_KEYS="  enter·vscode   u·browser   esc·volver"
_TUI_KEYS_PENDING="  enter·vscode   u·browser   x·skip SR   ctrl-d·limpiar todos   esc·volver"

# ── Helpers de extracción ──────────────────────────────────────────
# El nombre del problema es siempre la primera palabra de la línea.
# IMPORTANTE: las listas siempre emiten un espacio después del nombre
# antes de cualquier código ANSI, para que awk '{print $1}' sea limpio.

_cb_tui_name_from_line() {
    # Extrae el nombre limpio: strip ANSI primero, luego primer campo
    echo "$1" | sed $'s/\033\\[[0-9;]*m//g' | awk '{print $1}'
}

# Preview del problema (nombre = primera palabra)
_cb_tui_preview_cmd() {
    local meta="$CPBREW_META"
    printf '%s' "
n=\$(echo {} | sed \$'s/\\\\033\\\\[[0-9;]*m//g' | awk '{print \$1}');
f=\"${meta}/\${n}.txt\";
if [[ ! -f \"\$f\" ]]; then printf '\\033[2m  sin metadata\\033[0m\n'; exit; fi;
url=\$(grep '^url=' \"\$f\" | cut -d= -f2-);
disp=\$(grep '^display_name=' \"\$f\" | cut -d= -f2-);
grp=\$(grep '^group=' \"\$f\" | cut -d= -f2-);
att=\$(grep '^attempts=' \"\$f\" | cut -d= -f2-);
srn=\$(grep '^sr_next=' \"\$f\" | cut -d= -f2-);
srs=\$(grep '^sr_step=' \"\$f\" | cut -d= -f2-);
sri=\$(grep '^sr_intervals=' \"\$f\" | cut -d= -f2-);
tot=\$(echo \"\$sri\" | awk -F',' '{print NF}');
printf '\\033[1m%s\\033[0m\n' \"\$n\";
[[ -n \"\$disp\" ]] && printf '\\033[2m%s\\033[0m\n' \"\$disp\";
[[ -n \"\$grp\" ]]  && printf '\\033[2m%s\\033[0m\n' \"\$grp\";
printf '\\n';
[[ -n \"\$url\" ]] && printf '\\033[36m%s\\033[0m\n' \"\$url\" || printf '\\033[2m(sin URL)\\033[0m\n';
printf '\\n';
printf '\\033[2m  attempts  \\033[0m%s\n' \"\${att:-0}\";
printf '\\033[2m  sr next   \\033[0m%s\\033[2m  (%s/%s)\\033[0m\n' \"\${srn:--}\" \"\${srs:-0}\" \"\${tot:-?}\";
[[ -n \"\$sri\" ]] && printf '\\033[2m  sr plan   %s\\033[0m\n' \"\$sri\";
"
}

# Bind para abrir URL en browser
_cb_tui_url_bind_cmd() {
    local meta="$CPBREW_META"
    printf '%s' "n=\$(echo {} | sed \$'s/\\\\033\\\\[[0-9;]*m//g' | awk '{print \$1}'); url=\$(grep '^url=' \"${meta}/\${n}.txt\" 2>/dev/null | cut -d= -f2-); [ -n \"\$url\" ] && open \"\$url\""
}

# Bind para skip SR del problema seleccionado (set sr_next=done)
_cb_tui_skip_sr_bind_cmd() {
    local meta="$CPBREW_META"
    printf '%s' "n=\$(echo {} | sed \$'s/\\\\033\\\\[[0-9;]*m//g' | awk '{print \$1}'); [ -n \"\$n\" ] && sed -i '' 's|^sr_next=.*|sr_next=done|' \"${meta}/\${n}.txt\" && echo \"  skip SR: \$n\""
}

# Bind para limpiar TODOS los vencidos (ctrl-d en pendientes)
_cb_tui_clear_due_bind_cmd() {
    local meta="$CPBREW_META"
    local today
    today=$(_today)
    printf '%s' "today=\$(date +%Y-%m-%d); for f in \"${meta}\"/*.txt; do srn=\$(grep '^sr_next=' \"\$f\" | cut -d= -f2-); [ -n \"\$srn\" ] && [ \"\$srn\" != 'done' ] && [ \"\$srn\" <= \"\$today\" ] && sed -i '' 's|^sr_next=.*|sr_next=done|' \"\$f\"; done; echo '  ✓ vencidos limpiados'"
}

# Abre en VSCode el problema cuyo nombre es la primera palabra de la línea
_cb_tui_open_selection() {
    local name=$(_cb_tui_name_from_line "$1")
    [[ -z "$name" ]] && return
    local sb="$CPBREW_SANDBOX/${name}.cpp"
    if [[ -f "$sb" ]]; then
        "$_CODE" "$sb"
    else
        local orig=$(_cb_get_original_file "$name")
        [[ -n "$orig" && -f "$orig" ]] && "$_CODE" "$orig" || _warn "No se encontró archivo de ${BOLD}$name${X}."
    fi
}

# ── Generadores de listas ──────────────────────────────────────────
# REGLA: siempre hay un espacio entre el nombre y cualquier código ANSI.
# Así awk '{print $1}' extrae el nombre limpio sin codes pegados.

_cb_tui_pending_list() {
    local today=$(_today) f name done_once sr_next display attempts
    for f in $(ls -t "$CPBREW_SANDBOX"/*.cpp 2>/dev/null); do
        name=$(basename "$f" .cpp)
        _cb_cph_read_prob "$name" 2>/dev/null
        done_once=$(_cb_meta_get "$name" "done_once")
        sr_next=$(_cb_meta_get "$name" "sr_next")
        [[ "$done_once" != "1" ]] && continue
        [[ -z "$sr_next" || "$sr_next" == "done" ]] && continue
        [[ ! "$sr_next" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && continue
        [[ "$sr_next" > "$today" ]] && continue
        display=$(_cb_meta_get "$name" "display_name")
        attempts=$(_cb_meta_get "$name" "attempts")
        # Espacio obligatorio después del nombre antes de cualquier ANSI
        printf '%s  ' "$name"
        [[ -n "$display" ]] && printf '\033[2m%-30s\033[0m  ' "$display" || printf '%-32s' ""
        printf '\033[33m%s\033[0m  \033[2ma:%s\033[0m\n' "$sr_next" "${attempts:-0}"
    done
}

_cb_tui_sandbox_list() {
    local today=$(_today) f name done_once sr_next display attempts tag
    for f in $(ls -t "$CPBREW_SANDBOX"/*.cpp 2>/dev/null); do
        name=$(basename "$f" .cpp)
        _cb_cph_read_prob "$name" 2>/dev/null
        done_once=$(_cb_meta_get "$name" "done_once")
        sr_next=$(_cb_meta_get "$name" "sr_next")
        display=$(_cb_meta_get "$name" "display_name")
        attempts=$(_cb_meta_get "$name" "attempts")
        if [[ "$done_once" == "1" ]]; then
            if [[ -n "$sr_next" && "$sr_next" != "done" ]] && \
               [[ "$sr_next" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && \
               [[ "$sr_next" < "$today" || "$sr_next" == "$today" ]]; then
                tag="\033[33mdue:$sr_next\033[0m"
            elif [[ "$sr_next" == "done" ]]; then
                tag="\033[32mdone\033[0m"
            else
                tag="\033[2msr:${sr_next:--}\033[0m"
            fi
        else
            tag="\033[2mnuevo\033[0m"
        fi
        # Espacio obligatorio después del nombre antes de cualquier ANSI
        printf '%s  ' "$name"
        [[ -n "$display" ]] && printf '\033[2m%-30s\033[0m  ' "$display" || printf '%-32s' ""
        printf '%b  \033[2ma:%s\033[0m\n' "$tag" "${attempts:-0}"
    done
}

_cb_tui_sr_list() {
    local today=$(_today)
    _cb_sr_rows_sorted | awk -F'|' -v today="$today" '{
        d=$1; n=$2; s=$3; i=$4;
        gsub(/[[:space:]]/, "", d); gsub(/[[:space:]]/, "", n); gsub(/[[:space:]]/, "", s);
        split(i, arr, ","); total=length(arr);
        # Color amarillo si es hoy o pasado
        dcol = (d <= today) ? "\033[33m" d "\033[0m" : d;
        printf "%s  \033[2m%-12s\033[0m  \033[2mpaso:%s/%d\033[0m\n", n, dcol, s, total
    }'
}

_cb_tui_log_list() {
    [[ ! -s "$CPBREW_STATS/log" ]] && return
    awk '{lines[NR]=$0} END {for(i=NR;i>=1;i--) print lines[i]}' "$CPBREW_STATS/log" | \
    awk -F'|' '{
        d=$1; n=$2; t=$3; r=$5;
        gsub(/^ +| +$/,"",d); gsub(/^ +| +$/,"",n);
        gsub(/^ +| +$/,"",t); gsub(/^ +| +$/,"",r);
        if (n=="") next;
        tc = (t=="NEW")   ? "\033[36mNEW  \033[0m" : "\033[2mRETRY\033[0m";
        rc = (r=="solo")   ? "\033[32msolo\033[0m"    :
             (r=="1 hint") ? "\033[33m1 hint\033[0m"  :
                             "\033[31m" r "\033[0m";
        printf "%s  \033[2m%s\033[0m  %b  %b\n", n, d, tc, rc
    }'
}

# ── Vistas ─────────────────────────────────────────────────────────

_cb_tui_pendientes() {
    local list preview ubind skip_bind clear_bind choice
    list=$(_cb_tui_pending_list)
    if [[ -z "$list" ]]; then
        echo ""; echo "  ${G}✓${X}  sin pendientes para hoy"; echo ""
        sleep 1; return
    fi
    preview=$(_cb_tui_preview_cmd)
    ubind=$(_cb_tui_url_bind_cmd)
    skip_bind=$(_cb_tui_skip_sr_bind_cmd)
    clear_bind=$(_cb_tui_clear_due_bind_cmd)
    choice=$(echo "$list" | fzf \
        --prompt " pendientes  " \
        --header "$_TUI_KEYS_PENDING" \
        --height 90% \
        --border rounded \
        --ansi \
        --no-sort \
        --preview "$preview" \
        --preview-window "right:44%:wrap:border-left" \
        --bind "u:execute($ubind)" \
        --bind "x:execute-silent($skip_bind)+reload(source $CPBREW_ROOT/cpbrew.zsh 2>/dev/null; _cb_tui_pending_list)" \
        --bind "ctrl-d:execute($clear_bind)+reload(source $CPBREW_ROOT/cpbrew.zsh 2>/dev/null; _cb_tui_pending_list)" \
        $=_TUI_THEME \
        2>/dev/null)
    [[ -z "$choice" ]] && return
    _cb_tui_open_selection "$choice"
}

_cb_tui_sandbox() {
    local list preview ubind choice
    list=$(_cb_tui_sandbox_list)
    if [[ -z "$list" ]]; then
        echo ""; echo "  ${DIM}sandbox vacío${X}"; echo ""
        sleep 1; return
    fi
    preview=$(_cb_tui_preview_cmd)
    ubind=$(_cb_tui_url_bind_cmd)
    choice=$(echo "$list" | fzf \
        --prompt " sandbox  " \
        --header "$_TUI_KEYS" \
        --height 90% \
        --border rounded \
        --ansi \
        --no-sort \
        --preview "$preview" \
        --preview-window "right:44%:wrap:border-left" \
        --bind "u:execute($ubind)" \
        $=_TUI_THEME \
        2>/dev/null)
    [[ -z "$choice" ]] && return
    _cb_tui_open_selection "$choice"
}

_cb_tui_sr_agenda() {
    local list preview ubind skip_bind clear_bind choice
    list=$(_cb_tui_sr_list)
    if [[ -z "$list" ]]; then
        echo ""; echo "  ${DIM}sin revisiones programadas${X}"; echo ""
        sleep 1; return
    fi
    preview=$(_cb_tui_preview_cmd)
    ubind=$(_cb_tui_url_bind_cmd)
    skip_bind=$(_cb_tui_skip_sr_bind_cmd)
    clear_bind=$(_cb_tui_clear_due_bind_cmd)
    choice=$(echo "$list" | fzf \
        --prompt " revisiones  " \
        --header "  enter·vscode   u·browser   x·skip SR   ctrl-d·limpiar vencidos   esc·volver" \
        --height 90% \
        --border rounded \
        --ansi \
        --no-sort \
        --preview "$preview" \
        --preview-window "right:44%:wrap:border-left" \
        --bind "u:execute($ubind)" \
        --bind "x:execute-silent($skip_bind)+reload(source $CPBREW_ROOT/cpbrew.zsh 2>/dev/null; _cb_tui_sr_list)" \
        --bind "ctrl-d:execute($clear_bind)+reload(source $CPBREW_ROOT/cpbrew.zsh 2>/dev/null; _cb_tui_sr_list)" \
        $=_TUI_THEME \
        2>/dev/null)
    [[ -z "$choice" ]] && return
    _cb_tui_open_selection "$choice"
}

_cb_tui_log_view() {
    local list preview ubind choice
    list=$(_cb_tui_log_list)
    if [[ -z "$list" ]]; then
        echo ""; echo "  ${DIM}log vacío${X}"; echo ""
        sleep 1; return
    fi
    preview=$(_cb_tui_preview_cmd)
    ubind=$(_cb_tui_url_bind_cmd)
    choice=$(echo "$list" | fzf \
        --prompt " historial  " \
        --header "$_TUI_KEYS" \
        --height 90% \
        --border rounded \
        --ansi \
        --no-sort \
        --preview "$preview" \
        --preview-window "right:44%:wrap:border-left" \
        --bind "u:execute($ubind)" \
        $=_TUI_THEME \
        2>/dev/null)
    [[ -z "$choice" ]] && return
    _cb_tui_open_selection "$choice"
}

# ── Menú principal ─────────────────────────────────────────────────

_cb_tui() {
    _cb_init
    if ! _cb_has_fzf; then
        _warn "cpbrew ui requiere fzf: ${C}brew install fzf${X}"
        _cb_help_main; return
    fi
    while true; do
        local total=$(cat "$CPBREW_STATS/total" 2>/dev/null || echo 0)
        local streak=$(cat "$CPBREW_STATS/streak" 2>/dev/null || echo 0)
        local today=$(_today)
        # Contar pendientes
        local pc=0
        for f in "$CPBREW_SANDBOX"/*.cpp(N); do
            local _dn=$(_cb_meta_get "$(basename "$f" .cpp)" "done_once")
            local _sn=$(_cb_meta_get "$(basename "$f" .cpp)" "sr_next")
            if [[ "$_dn" == "1" && -n "$_sn" && "$_sn" != "done" ]] && \
               [[ "$_sn" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && \
               [[ "$_sn" < "$today" || "$_sn" == "$today" ]]; then
                pc=$((pc + 1))
            fi
        done
        local sbc=$(ls "$CPBREW_SANDBOX"/*.cpp 2>/dev/null | wc -l | tr -d ' ')
        # Header con stats; pendientes en amarillo si los hay
        local hdr="  ☕  $total problemas  ·  🔥 $streak días  ·  $today"
        [[ $pc -gt 0 ]] && hdr="$hdr  ·  \033[33m$pc pendientes\033[0m"
        # Etiquetas del menú con alineación fija
        local pend_label
        [[ $pc -gt 0 ]] && pend_label="\033[33m$pc due hoy\033[0m" || pend_label="\033[2mal día\033[0m"
        local choice
        choice=$(printf '%s\n' \
            "  pendientes      $pend_label" \
            "  sandbox         \033[2m$sbc problemas\033[0m" \
            "  revisiones      \033[2magenda SR\033[0m" \
            "  limpiar due     \033[2mmarcar vencidos como hechos\033[0m" \
            "  historial       \033[2mlog de soluciones\033[0m" \
            "  stats           \033[2mprogreso y racha\033[0m" \
            "  ──" \
            "  done            \033[2mregistrar solución actual\033[0m" \
            "  retry           \033[2mreintentar problema\033[0m" \
            "  nuevo           \033[2mcrear en sandbox\033[0m" \
            "  ir a            \033[2mnavegar carpetas\033[0m" \
            "  git             \033[2madd · commit · push\033[0m" \
            "  ──" \
            "  salir" \
            | fzf \
                --prompt "  ☕  " \
                --header "$hdr" \
                --height 80% \
                --border rounded \
                --no-sort \
                --ansi \
                --bind "esc:abort" \
                $=_TUI_THEME \
                2>/dev/null)
        [[ -z "$choice" ]] && break
        case "$choice" in
            *pendientes*)    _cb_tui_pendientes ;;
            *sandbox*)       _cb_tui_sandbox ;;
            *revisiones*)    _cb_tui_sr_agenda ;;
            *"limpiar due"*) clear; _cb_sr clear-due; echo ""; echo -n "  enter para continuar..."; read -r ;;
            *historial*)     _cb_tui_log_view ;;
            *stats*)         clear; _cb_stats; echo -n "  enter para continuar..."; read -r ;;
            *done*)          clear; _cb_done ;;
            *retry*)         clear; _cb_retry ;;
            *nuevo*)         clear; echo -n "  nombre del problema: "; read pname; [[ -n "$pname" ]] && _cb_new "$pname" ;;
            *"ir a"*)        clear; _cb_ls; echo -n "  destino: "; read dest; [[ -n "$dest" ]] && _cb_go "$dest" ;;
            *git*)           clear; _cb_git ;;
            *──*)            : ;;
            *)               break ;;
        esac
    done
    clear
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
        retry-ls|ls-retry) _cb_retry_ls "$@" ;;
        retry-rm|rm-retry) _cb_retry_rm "$@" ;;
        rm)           _cb_rm_problem "$@" ;;
        mv)           _cb_move_problem "$@" ;;
        where)        _cb_where_problem "$@" ;;
        open)         _cb_open_url "$@" ;;
        personal)     _cb_personal "$@" ;;
        sr)           _cb_sr "$@" ;;
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
        ui|tui)       _cb_tui ;;
        help)         _cb_help_main ;;
        "")           _cb_tui ;;
        *)
            _err "Comando '${cmd}' no reconocido."
            echo "  Usa ${C}cpbrew help${X} para ver los comandos."
            ;;
    esac
}
