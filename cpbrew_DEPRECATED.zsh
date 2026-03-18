#!/bin/zsh

# ╔═══════════════════════════════════════════════════════════════════╗
# ║  ☕  cpbrew — CLI de Programación Competitiva                    ║
# ║  Agustin Alexis Reyes Castillo · coffeeMeitt                    ║
# ║                                                                   ║
# ║  INSTALACIÓN:                                                     ║
# ║    echo 'source /Users/coffee/00-personal/cp_solutions/cpbrew.zsh' >> ~/.zshrc
# ║    source ~/.zshrc                                                ║
# ╚═══════════════════════════════════════════════════════════════════╝

# ─── Config ──────────────────────────────────────────────────────────────────
CPBREW_ROOT="/Users/coffee/00-personal/cp_solutions"
CPBREW_STATS="$HOME/.cpbrew_stats"
CPBREW_SANDBOX="$CPBREW_ROOT/.sandbox"

# ─── Colores ─────────────────────────────────────────────────────────────────
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
B='\033[0;34m'
C='\033[0;36m'
M='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
X='\033[0m'

# ─── Init stats ──────────────────────────────────────────────────────────────
_cb_init() {
    mkdir -p "$CPBREW_STATS" "$CPBREW_SANDBOX"
    [[ ! -f "$CPBREW_STATS/total" ]]     && echo "0" > "$CPBREW_STATS/total"
    [[ ! -f "$CPBREW_STATS/solo" ]]      && echo "0" > "$CPBREW_STATS/solo"
    [[ ! -f "$CPBREW_STATS/hint" ]]      && echo "0" > "$CPBREW_STATS/hint"
    [[ ! -f "$CPBREW_STATS/streak" ]]    && echo "0" > "$CPBREW_STATS/streak"
    [[ ! -f "$CPBREW_STATS/last_date" ]] && date +%Y-%m-%d > "$CPBREW_STATS/last_date"
    [[ ! -f "$CPBREW_STATS/log" ]]       && touch "$CPBREW_STATS/log"
}

# ─── Template C++ ────────────────────────────────────────────────────────────
_cb_write_template() {
    local file=$1
    local today=$(date +%Y-%m-%d)
    cat > "$file" << CPPTEMPLATE
// ┌─────────────────────────────────────────────┐
// │  Autor:      Agustin Alexis Reyes Castillo  │
// │  CF:         codeforces.com/profile/coffeeMeitt │
// │  CSES:       cses.fi/user/318632            │
// ├─────────────────────────────────────────────┤
// │  Problema:                                  │
// │  Plataforma:                                │
// │  Link:                                      │
// │  Dificultad:                                │
// │  Fecha:      $today                  │
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

# ─── Separador decorativo ────────────────────────────────────────────────────
_cb_sep() {
    echo "${DIM}  ──────────────────────────────────────────${X}"
}

# ─── cpbrew help ─────────────────────────────────────────────────────────────
_cb_help() {
    clear
    echo ""
    echo "${BOLD}${C}  ╔══════════════════════════════════════════╗${X}"
    echo "${BOLD}${C}  ║  ☕  cpbrew · coffeeMeitt               ║${X}"
    echo "${BOLD}${C}  ║  ICPC Training CLI                      ║${X}"
    echo "${BOLD}${C}  ╚══════════════════════════════════════════╝${X}"
    echo ""
    _cb_sep
    echo "  ${BOLD}NAVEGACIÓN${X}"
    _cb_sep
    echo "  ${G}cpbrew go${X} ${Y}<destino>${X}           Abrir carpeta en VSCode"
    echo "  ${G}cpbrew ls${X}                   Ver todos los destinos"
    echo ""
    _cb_sep
    echo "  ${BOLD}PROBLEMAS${X}"
    _cb_sep
    echo "  ${G}cpbrew new${X} ${Y}<nombre>${X}          Crear .cpp con template"
    echo "  ${G}cpbrew done${X}                 Registrar problema resuelto"
    echo "  ${G}cpbrew log${X}                  Ver historial de problemas"
    echo ""
    _cb_sep
    echo "  ${BOLD}SANDBOX${X} ${DIM}(repetición espaciada)${X}"
    _cb_sep
    echo "  ${G}cpbrew sb new${X} ${Y}<nombre>${X}       Crear problema en sandbox"
    echo "  ${G}cpbrew sb ls${X}                Ver problemas en sandbox"
    echo "  ${G}cpbrew sb retry${X} ${Y}<nombre>${X}     Nuevo intento"
    echo "  ${G}cpbrew sb diff${X} ${Y}<nombre>${X}      Comparar intentos en VSCode"
    echo ""
    _cb_sep
    echo "  ${BOLD}IMPORT${X}"
    _cb_sep
    echo "  ${G}cpbrew import${X} ${Y}<url|ruta>${X}     Importar solución + diff opcional"
    echo ""
    _cb_sep
    echo "  ${BOLD}STATS${X}"
    _cb_sep
    echo "  ${G}cpbrew stats${X}                Ver progreso y barras"
    echo "  ${G}cpbrew streak${X}               Ver racha actual"
    echo ""
    _cb_sep
    echo "  ${BOLD}UTILS${X}"
    _cb_sep
    echo "  ${G}cpbrew git${X}                  add + commit + push"
    echo "  ${G}cpbrew help${X}                 Mostrar esta ayuda"
    echo ""
}

# ─── cpbrew ls ───────────────────────────────────────────────────────────────
_cb_ls() {
    echo ""
    echo "${BOLD}${C}  ☕  Destinos disponibles${X}"
    echo ""
    echo "${BOLD}  ── CSES ─────────────────────────────────────${X}"
    printf "  ${Y}%-10s${X} ${DIM}%-30s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "intro"   "introductory_problems"    "sort"    "sorting_and_searching"
    printf "  ${Y}%-10s${X} ${DIM}%-30s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "dp"      "dynamic_programming"      "graph"   "graph_algorithms"
    printf "  ${Y}%-10s${X} ${DIM}%-30s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "agraph"  "advanced_graph_problems"  "tree"    "tree_algorithms"
    printf "  ${Y}%-10s${X} ${DIM}%-30s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "range"   "range_queries"            "math"    "mathematics"
    printf "  ${Y}%-10s${X} ${DIM}%-30s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "string"  "string_algorithms"        "count"   "counting_problems"
    printf "  ${Y}%-10s${X} ${DIM}%-30s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "bitwise" "bitwise_operations"       "geo"     "geometry"
    printf "  ${Y}%-10s${X} ${DIM}%-30s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "slide"   "sliding_window_problems"  "const"   "construction_problems"
    printf "  ${Y}%-10s${X} ${DIM}%-30s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "inter"   "interactive_problems"     "adv"     "advanced_techniques"
    printf "  ${Y}%-10s${X} ${DIM}%-30s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "add1"    "additional_problems_I"    "add2"    "additional_problems_II"
    echo ""
    echo "${BOLD}  ── OTRAS ────────────────────────────────────${X}"
    printf "  ${Y}%-10s${X} ${DIM}%-30s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "cf"      "CODEFORCES"               "icpc"    "ICPC/regionales"
    printf "  ${Y}%-10s${X} ${DIM}%-30s${X}  ${Y}%-10s${X} ${DIM}%s${X}\n" "sim"     "ICPC/simulacros"          "sandbox" ".sandbox"
    printf "  ${Y}%-10s${X} ${DIM}%-30s${X}\n"                              "root"    "raíz del repo"
    echo ""
}

# ─── cpbrew go ───────────────────────────────────────────────────────────────
_cb_go() {
    local dest=$1
    if [[ -z "$dest" ]]; then
        echo "  ${R}✗${X} Especifica un destino. Usa ${C}cpbrew ls${X} para ver opciones."
        return 1
    fi

    local target_path=""
    case $dest in
        intro)   target_path="CSES/introductory_problems" ;;
        sort)    target_path="CSES/sorting_and_searching" ;;
        dp)      target_path="CSES/dynamic_programming" ;;
        graph)   target_path="CSES/graph_algorithms" ;;
        agraph)  target_path="CSES/advanced_graph_problems" ;;
        tree)    target_path="CSES/tree_algorithms" ;;
        range)   target_path="CSES/range_queries" ;;
        math)    target_path="CSES/mathematics" ;;
        string)  target_path="CSES/string_algorithms" ;;
        count)   target_path="CSES/counting_problems" ;;
        bitwise) target_path="CSES/bitwise_operations" ;;
        geo)     target_path="CSES/geometry" ;;
        slide)   target_path="CSES/sliding_window_problems" ;;
        const)   target_path="CSES/construction_problems" ;;
        inter)   target_path="CSES/interactive_problems" ;;
        adv)     target_path="CSES/advanced_techniques" ;;
        add1)    target_path="CSES/additional_problems_I" ;;
        add2)    target_path="CSES/additional_problems_II" ;;
        cf)      target_path="CODEFORCES" ;;
        icpc)    target_path="ICPC/regionales" ;;
        sim)     target_path="ICPC/simulacros" ;;
        sandbox) target_path=".sandbox" ;;
        root)    target_path="" ;;
        *)
            echo "  ${R}✗${X} Destino '${dest}' no encontrado. Usa ${C}cpbrew ls${X}."
            return 1
            ;;
    esac

    local fullpath="$CPBREW_ROOT/$target_path"
    mkdir -p "$fullpath"
    cd "$fullpath"
    echo "  ${G}✓${X} ${BOLD}$fullpath${X}"
    code .
}

# ─── cpbrew new ──────────────────────────────────────────────────────────────
_cb_new() {
    local name=$1
    if [[ -z "$name" ]]; then
        echo "  ${R}✗${X} Especifica un nombre. Ej: ${C}cpbrew new 1900A${X}"
        return 1
    fi
    local file="${name}.cpp"
    if [[ -f "$file" ]]; then
        echo "  ${Y}⚠${X}  El archivo ${BOLD}$file${X} ya existe."
        return 1
    fi
    _cb_write_template "$file"
    echo "  ${G}✓${X} Creado ${BOLD}$file${X}"
    code "$file"
}

# ─── cpbrew sandbox ──────────────────────────────────────────────────────────
_cb_sandbox() {
    local subcmd=$1
    shift

    case $subcmd in
        new)
            local name=$1
            if [[ -z "$name" ]]; then
                echo "  ${R}✗${X} Especifica un nombre. Ej: ${C}cpbrew sb new sum-of-divisors${X}"
                return 1
            fi
            local dir="$CPBREW_SANDBOX/$name"
            mkdir -p "$dir"
            local attempt=1
            if ls "$dir"/attempt_*.cpp 2>/dev/null | grep -q .; then
                attempt=$(ls "$dir"/attempt_*.cpp | wc -l | tr -d ' ')
                attempt=$((attempt + 1))
            fi
            local file="$dir/attempt_${attempt}.cpp"
            _cb_write_template "$file"
            if [[ ! -f "$dir/meta.txt" ]]; then
                printf "problema=%s\ncreado=%s\nintentos=1\n" "$name" "$(date +%Y-%m-%d)" > "$dir/meta.txt"
            else
                sed -i '' "s/intentos=.*/intentos=$attempt/" "$dir/meta.txt"
            fi
            echo ""
            echo "  ${G}✓${X} ${BOLD}Sandbox:${X} $name"
            echo "  ${DIM}Intento #${attempt} → $file${X}"
            echo ""
            code "$file"
            ;;

        retry)
            local name=$1
            if [[ -z "$name" ]]; then
                echo "  ${R}✗${X} Especifica el nombre del problema."
                return 1
            fi
            local dir="$CPBREW_SANDBOX/$name"
            if [[ ! -d "$dir" ]]; then
                echo "  ${R}✗${X} '$name' no encontrado. Usa ${C}cpbrew sb ls${X}."
                return 1
            fi
            local attempt=$(ls "$dir"/attempt_*.cpp 2>/dev/null | wc -l | tr -d ' ')
            attempt=$((attempt + 1))
            local file="$dir/attempt_${attempt}.cpp"
            _cb_write_template "$file"
            sed -i '' "s/intentos=.*/intentos=$attempt/" "$dir/meta.txt"
            echo ""
            echo "  ${G}✓${X} ${BOLD}$name${X} — intento #${attempt}"
            echo "  ${DIM}$file${X}"
            echo ""
            code "$file"
            ;;

        diff)
            local name=$1
            if [[ -z "$name" ]]; then
                echo "  ${R}✗${X} Especifica el nombre del problema."
                return 1
            fi
            local dir="$CPBREW_SANDBOX/$name"
            if [[ ! -d "$dir" ]]; then
                echo "  ${R}✗${X} '$name' no encontrado."
                return 1
            fi
            local files=($(ls "$dir"/attempt_*.cpp 2>/dev/null | sort))
            local count=${#files[@]}
            if [[ $count -lt 2 ]]; then
                echo "  ${Y}⚠${X}  Necesitas al menos 2 intentos para comparar."
                echo "  Usa ${C}cpbrew sb retry $name${X} para agregar uno."
                return 1
            fi
            local prev="${files[$((count-1))]}"
            local last="${files[$count]}"
            echo ""
            echo "  ${C}→${X} Abriendo diff en VSCode..."
            echo "  ${DIM}← $prev${X}"
            echo "  ${DIM}→ $last${X}"
            echo ""
            code --diff "$prev" "$last"
            ;;

        ls)
            echo ""
            echo "${BOLD}${C}  ☕  Sandbox — problemas${X}"
            echo ""
            if [[ -z "$(ls -A $CPBREW_SANDBOX 2>/dev/null)" ]]; then
                echo "  ${DIM}Vacío. Usa ${C}cpbrew sb new <nombre>${DIM} para agregar.${X}"
            else
                _cb_sep
                for dir in "$CPBREW_SANDBOX"/*/; do
                    [[ -d "$dir" ]] || continue
                    local name=$(basename "$dir")
                    local attempts=$(ls "$dir"/attempt_*.cpp 2>/dev/null | wc -l | tr -d ' ')
                    local created=$(grep "creado=" "$dir/meta.txt" 2>/dev/null | cut -d= -f2)
                    printf "  ${Y}%-28s${X}  ${G}%s intentos${X}  ${DIM}%s${X}\n" "$name" "$attempts" "$created"
                done
                _cb_sep
            fi
            echo ""
            ;;

        *)
            echo "  ${R}✗${X} Subcomando desconocido. Opciones: ${C}new, retry, diff, ls${X}"
            ;;
    esac
}

# ─── cpbrew import ───────────────────────────────────────────────────────────
_cb_import() {
    local src=$1
    if [[ -z "$src" ]]; then
        echo "  ${R}✗${X} Especifica una URL o ruta."
        echo "  Ej: ${C}cpbrew import https://raw.githubusercontent.com/...${X}"
        echo "  Ej: ${C}cpbrew import ~/Downloads/solution.cpp${X}"
        return 1
    fi

    echo -n "  Nombre para guardar (sin .cpp): "
    read fname
    [[ -z "$fname" ]] && echo "  ${R}✗${X} Nombre vacío." && return 1

    local dest="${fname}.cpp"

    if [[ "$src" == http* ]]; then
        if [[ "$src" == *"github.com"* && "$src" != *"raw.githubusercontent"* ]]; then
            src=$(echo "$src" | sed 's|github.com|raw.githubusercontent.com|' | sed 's|/blob/|/|')
        fi
        echo "  ${C}→${X} Descargando..."
        curl -s "$src" -o "$dest"
        [[ $? -ne 0 ]] && echo "  ${R}✗${X} No se pudo descargar." && return 1
    else
        [[ ! -f "$src" ]] && echo "  ${R}✗${X} Archivo no encontrado: $src" && return 1
        cp "$src" "$dest"
    fi

    echo "  ${G}✓${X} Importado como ${BOLD}$dest${X}"
    echo -n "  ¿Comparar con otro archivo? (ruta o Enter para omitir): "
    read cmp
    if [[ -n "$cmp" ]]; then
        [[ -f "$cmp" ]] && code --diff "$cmp" "$dest" || echo "  ${Y}⚠${X}  No encontrado, abriendo solo." && code "$dest"
    else
        code "$dest"
    fi
}

# ─── cpbrew done ─────────────────────────────────────────────────────────────
_cb_done() {
    _cb_init
    echo ""
    echo "${BOLD}${C}  ☕  Registrar problema${X}"
    _cb_sep
    echo -n "  Nombre: "
    read prob_name

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
    echo $((total + 1)) > "$CPBREW_STATS/total"

    if [[ $ropt == 1 ]]; then
        local s=$(cat "$CPBREW_STATS/solo"); echo $((s+1)) > "$CPBREW_STATS/solo"
    else
        local h=$(cat "$CPBREW_STATS/hint"); echo $((h+1)) > "$CPBREW_STATS/hint"
    fi

    local last=$(cat "$CPBREW_STATS/last_date")
    local today=$(date +%Y-%m-%d)
    local yesterday=$(date -v-1d +%Y-%m-%d)
    local streak=$(cat "$CPBREW_STATS/streak")

    if [[ "$last" == "$today" ]]; then
        :
    elif [[ "$last" == "$yesterday" ]]; then
        streak=$((streak+1)); echo $streak > "$CPBREW_STATS/streak"
    else
        streak=1; echo 1 > "$CPBREW_STATS/streak"
    fi
    echo "$today" > "$CPBREW_STATS/last_date"
    echo "$today | $prob_name | $rstr" >> "$CPBREW_STATS/log"

    echo ""
    _cb_sep
    echo "  ${G}✓${X} ${BOLD}$prob_name${X} registrado ${DIM}($rstr)${X}"
    echo "  Total: ${BOLD}$(cat $CPBREW_STATS/total)${X}  ·  Racha: ${M}${BOLD}${streak} días 🔥${X}"
    _cb_sep
    echo ""
}

# ─── cpbrew stats ────────────────────────────────────────────────────────────
_cb_stats() {
    _cb_init
    local total=$(cat "$CPBREW_STATS/total")
    local solo=$(cat "$CPBREW_STATS/solo")
    local hint=$(cat "$CPBREW_STATS/hint")
    local streak=$(cat "$CPBREW_STATS/streak")
    local solo_pct=0
    [[ $total -gt 0 ]] && solo_pct=$((solo*100/total))

    # Barra total /1000
    local f=$((total*30/1000)); [[ $f -gt 30 ]] && f=30
    local e=$((30-f))
    local bar="${G}"; for i in $(seq 1 $f); do bar+="█"; done
    bar+="${DIM}"; for i in $(seq 1 $e); do bar+="░"; done; bar+="${X}"

    # Barra mensual /150
    local month=$(date +%Y-%m)
    local mc=$(grep "^$month" "$CPBREW_STATS/log" 2>/dev/null | wc -l | tr -d ' ')
    local mf=$((mc*20/150)); [[ $mf -gt 20 ]] && mf=20
    local me=$((20-mf))
    local mbar="${C}"; for i in $(seq 1 $mf); do mbar+="█"; done
    mbar+="${DIM}"; for i in $(seq 1 $me); do mbar+="░"; done; mbar+="${X}"

    local sb=$(ls -d "$CPBREW_SANDBOX"/*/ 2>/dev/null | wc -l | tr -d ' ')

    echo ""
    echo "${BOLD}${C}  ╔══════════════════════════════════════════╗${X}"
    echo "${BOLD}${C}  ║  ☕  cpbrew stats · coffeeMeitt         ║${X}"
    echo "${BOLD}${C}  ╚══════════════════════════════════════════╝${X}"
    echo ""
    echo "  ${BOLD}Progreso${X} ${DIM}(meta: 1000 problemas)${X}"
    echo "  $bar  ${BOLD}$total${X}${DIM}/1000${X}"
    echo ""
    echo "  ${G}Solo (hard):${X}    ${BOLD}$solo${X}  ${DIM}(${solo_pct}%)${X}"
    echo "  ${Y}Con hint:${X}       ${BOLD}$hint${X}"
    echo "  ${C}En sandbox:${X}     ${BOLD}$sb${X} problemas"
    echo ""
    echo "  ${BOLD}Este mes${X} ${DIM}(meta: 150)${X}"
    echo "  $mbar  ${BOLD}$mc${X}${DIM}/150${X}  ${DIM}($((mc*100/150))%)${X}"
    echo ""
    echo "  ${BOLD}Racha actual:${X}  ${M}${BOLD}$streak días 🔥${X}"
    echo ""
}

# ─── cpbrew log ──────────────────────────────────────────────────────────────
_cb_log() {
    _cb_init
    echo ""
    echo "${BOLD}${C}  ☕  Historial — últimos 20${X}"
    _cb_sep
    if [[ ! -s "$CPBREW_STATS/log" ]]; then
        echo "  ${DIM}Vacío. Usa ${C}cpbrew done${DIM} para registrar.${X}"
    else
        tail -20 "$CPBREW_STATS/log" | while IFS= read -r line; do
            local d=$(echo "$line" | cut -d'|' -f1 | tr -d ' ')
            local n=$(echo "$line" | cut -d'|' -f2)
            local r=$(echo "$line" | cut -d'|' -f3 | tr -d ' ')
            if [[ "$r" == "solo" ]]; then
                printf "  ${DIM}%s${X}  ${G}✓${X}${BOLD}%s${X} ${DIM}(%s)${X}\n" "$d" "$n" "$r"
            else
                printf "  ${DIM}%s${X}  ${Y}~${X}${BOLD}%s${X} ${DIM}(%s)${X}\n" "$d" "$n" "$r"
            fi
        done
    fi
    _cb_sep
    echo ""
}

# ─── cpbrew streak ───────────────────────────────────────────────────────────
_cb_streak() {
    _cb_init
    local streak=$(cat "$CPBREW_STATS/streak")
    local last=$(cat "$CPBREW_STATS/last_date")
    echo ""
    echo "  ${M}${BOLD}☕  $streak días de racha 🔥${X}"
    echo "  ${DIM}Último registro: $last${X}"
    echo ""
}

# ─── cpbrew git ──────────────────────────────────────────────────────────────
_cb_git() {
    local curr=$(pwd)
    cd "$CPBREW_ROOT"
    echo "  ${C}→${X} git add ."
    git add .
    echo -n "  Commit message (Enter = fecha automática): "
    read msg
    [[ -z "$msg" ]] && msg="solve: $(date +%Y-%m-%d)"
    git commit -m "$msg"
    git push
    echo "  ${G}✓${X} Push exitoso"
    cd "$curr"
}

# ─── Router principal ─────────────────────────────────────────────────────────
cpbrew() {
    local cmd=$1
    shift
    case $cmd in
        go)           _cb_go "$@" ;;
        ls)           _cb_ls ;;
        new)          _cb_new "$@" ;;
        done)         _cb_done ;;
        log)          _cb_log ;;
        stats)        _cb_stats ;;
        streak)       _cb_streak ;;
        sb|sandbox)   _cb_sandbox "$@" ;;
        import)       _cb_import "$@" ;;
        git)          _cb_git ;;
        help|"")      _cb_help ;;
        *)
            echo "  ${R}✗${X} Comando '${cmd}' no reconocido."
            echo "  Usa ${C}cpbrew help${X} para ver los comandos."
            ;;
    esac
}
