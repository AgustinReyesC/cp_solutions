#!/bin/zsh

# ╔═══════════════════════════════════════════════════════════════╗
# ║   ☕  moka — CLI de Programación Competitiva                  ║
# ║   Agustin Alexis Reyes Castillo · coffeeMeitt                ║
# ╚═══════════════════════════════════════════════════════════════╝
#
# INSTALACIÓN:
#   Agrega al final de ~/.zshrc:
#     source ~/cp_solutions/moka.zsh
#   Luego:
#     source ~/.zshrc

# ─── Config ──────────────────────────────────────────────────────────────────
MOKA_ROOT="$HOME/cp_solutions"
MOKA_STATS="$HOME/.moka_stats"
MOKA_SANDBOX="$MOKA_ROOT/.sandbox"

# ─── Colores ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ─── Init ────────────────────────────────────────────────────────────────────
_moka_init() {
    mkdir -p "$MOKA_STATS"
    mkdir -p "$MOKA_SANDBOX"
    [[ ! -f "$MOKA_STATS/total" ]]     && echo "0" > "$MOKA_STATS/total"
    [[ ! -f "$MOKA_STATS/solo" ]]      && echo "0" > "$MOKA_STATS/solo"
    [[ ! -f "$MOKA_STATS/hint" ]]      && echo "0" > "$MOKA_STATS/hint"
    [[ ! -f "$MOKA_STATS/streak" ]]    && echo "0" > "$MOKA_STATS/streak"
    [[ ! -f "$MOKA_STATS/last_date" ]] && date +%Y-%m-%d > "$MOKA_STATS/last_date"
    [[ ! -f "$MOKA_STATS/log" ]]       && touch "$MOKA_STATS/log"
}

# ─── Template ────────────────────────────────────────────────────────────────
_moka_template() {
    local file=$1
    local today=$(date +%Y-%m-%d)
    cat > "$file" << TEMPLATE
// ─────────────────────────────────────────────
// Autor:      Agustin Alexis Reyes Castillo
// Codeforces: https://codeforces.com/profile/coffeeMeitt
// CSES:       https://cses.fi/user/318632
// ─────────────────────────────────────────────
// Problema:   
// Plataforma: 
// Link:       
// Dificultad: 
// Fecha:      $today
// ─────────────────────────────────────────────
// Técnica:    
// Resultado:  
// ─────────────────────────────────────────────
// Idea:
// 
// ─────────────────────────────────────────────

#pragma GCC optimize("O2")
#include <bits/stdc++.h>
using namespace std;

typedef long long           ll;
typedef pair<int,int>       pii;
typedef pair<ll,ll>         pll;
typedef vector<int>         vi;
typedef vector<ll>          vll;

const ll MOD  = 1e9 + 7;
const ll LINF = 1e18;
const int INF = 1e9;

#define pb          push_back
#define all(x)      (x).begin(), (x).end()
#define sz(x)       (int)(x).size()
#define rep(i,a,b)  for(int i = (a); i < (b); i++)

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
TEMPLATE
}

# ─── moka help ───────────────────────────────────────────────────────────────
_moka_help() {
    echo ""
    echo "${BOLD}${CYAN}  ☕  moka${RESET} ${DIM}— tu CLI de programación competitiva${RESET}"
    echo "  ${DIM}coffeeMeitt · ICPC Training · github.com/coffeeMeitt${RESET}"
    echo ""
    echo "${BOLD}  NAVEGACIÓN${RESET}"
    echo "  ${GREEN}moka go <destino>${RESET}          Abrir carpeta en VSCode"
    echo "  ${GREEN}moka ls${RESET}                    Ver todos los destinos"
    echo ""
    echo "${BOLD}  PROBLEMAS${RESET}"
    echo "  ${GREEN}moka new <nombre>${RESET}          Crear archivo con template"
    echo "  ${GREEN}moka done${RESET}                  Registrar problema resuelto"
    echo "  ${GREEN}moka log${RESET}                   Ver historial"
    echo ""
    echo "${BOLD}  SANDBOX (repetición espaciada)${RESET}"
    echo "  ${GREEN}moka sandbox new <nombre>${RESET}  Crear problema en sandbox"
    echo "  ${GREEN}moka sandbox ls${RESET}            Ver problemas en sandbox"
    echo "  ${GREEN}moka sandbox retry <nombre>${RESET} Nuevo intento de un problema"
    echo "  ${GREEN}moka sandbox diff <nombre>${RESET} Comparar intentos en VSCode"
    echo ""
    echo "${BOLD}  IMPORT${RESET}"
    echo "  ${GREEN}moka import <url>${RESET}          Importar desde GitHub (raw URL)"
    echo "  ${GREEN}moka import <ruta>${RESET}         Importar desde ruta local"
    echo ""
    echo "${BOLD}  STATS${RESET}"
    echo "  ${GREEN}moka stats${RESET}                 Ver progreso y racha"
    echo "  ${GREEN}moka streak${RESET}                Ver racha actual"
    echo ""
    echo "${BOLD}  UTILS${RESET}"
    echo "  ${GREEN}moka git${RESET}                   Push rápido al repo"
    echo "  ${GREEN}moka help${RESET}                  Mostrar esta ayuda"
    echo ""
}

# ─── moka ls ─────────────────────────────────────────────────────────────────
_moka_ls() {
    echo ""
    echo "${BOLD}${CYAN}  ☕  Destinos disponibles${RESET}"
    echo ""
    echo "${BOLD}  CSES${RESET}"
    echo "  ${YELLOW}intro${RESET}     introductory_problems      ${YELLOW}sort${RESET}      sorting_and_searching"
    echo "  ${YELLOW}dp${RESET}        dynamic_programming         ${YELLOW}graph${RESET}     graph_algorithms"
    echo "  ${YELLOW}agraph${RESET}    advanced_graph_problems     ${YELLOW}tree${RESET}      tree_algorithms"
    echo "  ${YELLOW}range${RESET}     range_queries               ${YELLOW}math${RESET}      mathematics"
    echo "  ${YELLOW}string${RESET}    string_algorithms           ${YELLOW}count${RESET}     counting_problems"
    echo "  ${YELLOW}bitwise${RESET}   bitwise_operations          ${YELLOW}geo${RESET}       geometry"
    echo "  ${YELLOW}slide${RESET}     sliding_window_problems     ${YELLOW}const${RESET}     construction_problems"
    echo "  ${YELLOW}inter${RESET}     interactive_problems        ${YELLOW}adv${RESET}       advanced_techniques"
    echo "  ${YELLOW}add1${RESET}      additional_problems_I       ${YELLOW}add2${RESET}      additional_problems_II"
    echo ""
    echo "${BOLD}  OTRAS${RESET}"
    echo "  ${YELLOW}cf${RESET}        Codeforces                  ${YELLOW}icpc${RESET}      ICPC Regionales"
    echo "  ${YELLOW}sim${RESET}       Simulacros                  ${YELLOW}root${RESET}      Raíz del repo"
    echo "  ${YELLOW}sandbox${RESET}   Sandbox de repetición       "
    echo ""
}

# ─── moka go ─────────────────────────────────────────────────────────────────
_moka_go() {
    declare -A DIRS
    DIRS=(
        [intro]="CSES/introductory_problems"
        [sort]="CSES/sorting_and_searching"
        [dp]="CSES/dynamic_programming"
        [graph]="CSES/graph_algorithms"
        [agraph]="CSES/advanced_graph_problems"
        [tree]="CSES/tree_algorithms"
        [range]="CSES/range_queries"
        [math]="CSES/mathematics"
        [string]="CSES/string_algorithms"
        [count]="CSES/counting_problems"
        [bitwise]="CSES/bitwise_operations"
        [geo]="CSES/geometry"
        [slide]="CSES/sliding_window_problems"
        [const]="CSES/construction_problems"
        [inter]="CSES/interactive_problems"
        [adv]="CSES/advanced_techniques"
        [add1]="CSES/additional_problems_I"
        [add2]="CSES/additional_problems_II"
        [cf]="CODEFORCES"
        [icpc]="ICPC/regionales"
        [sim]="ICPC/simulacros"
        [sandbox]=".sandbox"
        [root]=""
    )

    local dest=$1
    if [[ -z "$dest" ]]; then
        echo "${RED}  Error:${RESET} especifica un destino. Usa ${CYAN}moka ls${RESET} para ver opciones."
        return 1
    fi

    if [[ -z "${DIRS[$dest]+x}" ]]; then
        echo "${RED}  Error:${RESET} destino '${dest}' no encontrado."
        return 1
    fi

    local path="$MOKA_ROOT/${DIRS[$dest]}"
    mkdir -p "$path"
    cd "$path"
    echo "${GREEN}  ✓${RESET} ${BOLD}$path${RESET}"
    code .
}

# ─── moka new ────────────────────────────────────────────────────────────────
_moka_new() {
    local name=$1
    if [[ -z "$name" ]]; then
        echo "${RED}  Error:${RESET} especifica un nombre. Ej: ${CYAN}moka new 1900A${RESET}"
        return 1
    fi

    local file="${name}.cpp"
    if [[ -f "$file" ]]; then
        echo "${YELLOW}  ⚠${RESET}  El archivo ${BOLD}$file${RESET} ya existe."
        return 1
    fi

    _moka_template "$file"
    echo "${GREEN}  ✓${RESET} Creado ${BOLD}$file${RESET}"
    code "$file"
}

# ─── moka sandbox ────────────────────────────────────────────────────────────
_moka_sandbox() {
    local subcmd=$1
    shift

    case $subcmd in
        new)
            local name=$1
            if [[ -z "$name" ]]; then
                echo "${RED}  Error:${RESET} especifica un nombre. Ej: ${CYAN}moka sandbox new sum-of-divisors${RESET}"
                return 1
            fi
            local dir="$MOKA_SANDBOX/$name"
            mkdir -p "$dir"
            local attempt=1
            # contar intentos existentes
            if ls "$dir"/attempt_*.cpp 2>/dev/null | grep -q .; then
                attempt=$(ls "$dir"/attempt_*.cpp | wc -l | tr -d ' ')
                attempt=$((attempt + 1))
            fi
            local file="$dir/attempt_${attempt}.cpp"
            _moka_template "$file"
            # guardar metadata
            if [[ ! -f "$dir/meta.txt" ]]; then
                echo "problema=$name" > "$dir/meta.txt"
                echo "creado=$(date +%Y-%m-%d)" >> "$dir/meta.txt"
                echo "intentos=1" >> "$dir/meta.txt"
            else
                local prev=$(grep "intentos=" "$dir/meta.txt" | cut -d= -f2)
                sed -i '' "s/intentos=.*/intentos=$attempt/" "$dir/meta.txt"
            fi
            echo "${GREEN}  ✓${RESET} Sandbox: ${BOLD}$name${RESET} — intento #${attempt}"
            echo "  ${DIM}$file${RESET}"
            code "$file"
            ;;

        retry)
            local name=$1
            if [[ -z "$name" ]]; then
                echo "${RED}  Error:${RESET} especifica el nombre del problema."
                return 1
            fi
            local dir="$MOKA_SANDBOX/$name"
            if [[ ! -d "$dir" ]]; then
                echo "${RED}  Error:${RESET} problema '${name}' no encontrado en sandbox."
                echo "  Usa ${CYAN}moka sandbox ls${RESET} para ver los disponibles."
                return 1
            fi
            local attempt=$(ls "$dir"/attempt_*.cpp 2>/dev/null | wc -l | tr -d ' ')
            attempt=$((attempt + 1))
            local file="$dir/attempt_${attempt}.cpp"
            _moka_template "$file"
            sed -i '' "s/intentos=.*/intentos=$attempt/" "$dir/meta.txt"
            echo "${GREEN}  ✓${RESET} ${BOLD}$name${RESET} — nuevo intento #${attempt}"
            echo "  ${DIM}$file${RESET}"
            code "$file"
            ;;

        diff)
            local name=$1
            if [[ -z "$name" ]]; then
                echo "${RED}  Error:${RESET} especifica el nombre del problema."
                return 1
            fi
            local dir="$MOKA_SANDBOX/$name"
            if [[ ! -d "$dir" ]]; then
                echo "${RED}  Error:${RESET} problema '${name}' no encontrado."
                return 1
            fi
            local files=($(ls "$dir"/attempt_*.cpp 2>/dev/null | sort))
            local count=${#files[@]}
            if [[ $count -lt 2 ]]; then
                echo "${YELLOW}  ⚠${RESET}  Necesitas al menos 2 intentos para comparar."
                echo "  Usa ${CYAN}moka sandbox retry $name${RESET} para agregar un intento."
                return 1
            fi
            # Comparar último vs penúltimo
            local prev=${files[$((count-1))]}
            local last=${files[$count]}
            echo "${CYAN}  → Comparando intentos en VSCode...${RESET}"
            echo "  ${DIM}$prev${RESET}"
            echo "  ${DIM}$last${RESET}"
            code --diff "$prev" "$last"
            ;;

        ls)
            echo ""
            echo "${BOLD}${CYAN}  ☕  Sandbox — problemas${RESET}"
            echo ""
            if [[ -z "$(ls -A $MOKA_SANDBOX 2>/dev/null)" ]]; then
                echo "  ${DIM}Vacío. Usa ${CYAN}moka sandbox new <nombre>${DIM} para agregar.${RESET}"
            else
                for dir in "$MOKA_SANDBOX"/*/; do
                    local name=$(basename "$dir")
                    local attempts=$(ls "$dir"/attempt_*.cpp 2>/dev/null | wc -l | tr -d ' ')
                    local created=$(grep "creado=" "$dir/meta.txt" 2>/dev/null | cut -d= -f2)
                    printf "  ${YELLOW}%-30s${RESET} ${DIM}%s intentos · creado %s${RESET}\n" "$name" "$attempts" "$created"
                done
            fi
            echo ""
            ;;

        *)
            echo "${RED}  Error:${RESET} subcomando desconocido."
            echo "  Opciones: ${CYAN}new, retry, diff, ls${RESET}"
            ;;
    esac
}

# ─── moka import ─────────────────────────────────────────────────────────────
_moka_import() {
    local source=$1
    if [[ -z "$source" ]]; then
        echo "${RED}  Error:${RESET} especifica una URL o ruta local."
        echo "  Ej: ${CYAN}moka import https://raw.githubusercontent.com/...${RESET}"
        echo "  Ej: ${CYAN}moka import ~/Downloads/solution.cpp${RESET}"
        return 1
    fi

    echo -n "  Nombre para el archivo (sin .cpp): "
    read fname
    if [[ -z "$fname" ]]; then
        echo "${RED}  Error:${RESET} nombre vacío."
        return 1
    fi

    local dest="${fname}.cpp"

    # URL o ruta local
    if [[ "$source" == http* ]]; then
        # Convertir URL de GitHub a raw si es necesario
        if [[ "$source" == *"github.com"* && "$source" != *"raw.githubusercontent"* ]]; then
            source=$(echo "$source" | sed 's|github.com|raw.githubusercontent.com|' | sed 's|/blob/|/|')
        fi
        echo "${CYAN}  → Descargando...${RESET}"
        curl -s "$source" -o "$dest"
        if [[ $? -ne 0 ]]; then
            echo "${RED}  Error:${RESET} no se pudo descargar la URL."
            return 1
        fi
    else
        # Ruta local
        if [[ ! -f "$source" ]]; then
            echo "${RED}  Error:${RESET} archivo no encontrado: $source"
            return 1
        fi
        cp "$source" "$dest"
    fi

    echo "${GREEN}  ✓${RESET} Importado como ${BOLD}$dest${RESET}"

    # Preguntar si comparar con archivo existente
    echo -n "  ¿Comparar con otro archivo? (ruta o Enter para omitir): "
    read compare_with
    if [[ -n "$compare_with" ]]; then
        if [[ -f "$compare_with" ]]; then
            code --diff "$compare_with" "$dest"
        else
            echo "${YELLOW}  ⚠${RESET}  Archivo para comparar no encontrado, abriendo solo."
            code "$dest"
        fi
    else
        code "$dest"
    fi
}

# ─── moka done ───────────────────────────────────────────────────────────────
_moka_done() {
    _moka_init

    echo ""
    echo "${BOLD}  ☕  Registrar problema${RESET}"
    echo ""
    echo -n "  Nombre del problema: "
    read prob_name

    echo "  Resultado:"
    echo "  ${GREEN}1${RESET}) Solo (hard)"
    echo "  ${YELLOW}2${RESET}) Con 1 hint"
    echo "  ${RED}3${RESET}) Con 2+ hints"
    echo -n "  Opción: "
    read result_opt

    local result_str
    case $result_opt in
        1) result_str="solo" ;;
        2) result_str="1 hint" ;;
        3) result_str="2+ hints" ;;
        *) result_str="desconocido" ;;
    esac

    local total=$(cat "$MOKA_STATS/total")
    echo $((total + 1)) > "$MOKA_STATS/total"

    if [[ $result_opt == 1 ]]; then
        local solo=$(cat "$MOKA_STATS/solo")
        echo $((solo + 1)) > "$MOKA_STATS/solo"
    else
        local hint=$(cat "$MOKA_STATS/hint")
        echo $((hint + 1)) > "$MOKA_STATS/hint"
    fi

    # Racha
    local last_date=$(cat "$MOKA_STATS/last_date")
    local today=$(date +%Y-%m-%d)
    local streak=$(cat "$MOKA_STATS/streak")
    local yesterday=$(date -v-1d +%Y-%m-%d)

    if [[ "$last_date" == "$today" ]]; then
        : # mismo día, no cambia racha
    elif [[ "$last_date" == "$yesterday" ]]; then
        echo $((streak + 1)) > "$MOKA_STATS/streak"
        streak=$((streak + 1))
    else
        echo "1" > "$MOKA_STATS/streak"
        streak=1
    fi
    echo "$today" > "$MOKA_STATS/last_date"

    echo "$(date +%Y-%m-%d) | $prob_name | $result_str" >> "$MOKA_STATS/log"

    echo ""
    echo "${GREEN}  ✓${RESET} ${BOLD}$prob_name${RESET} registrado (${result_str})"
    echo "  Total: ${BOLD}$(cat $MOKA_STATS/total)${RESET} problemas  ·  Racha: ${MAGENTA}${BOLD}${streak} días 🔥${RESET}"
    echo ""
}

# ─── moka stats ──────────────────────────────────────────────────────────────
_moka_stats() {
    _moka_init

    local total=$(cat "$MOKA_STATS/total")
    local solo=$(cat "$MOKA_STATS/solo")
    local hint=$(cat "$MOKA_STATS/hint")
    local streak=$(cat "$MOKA_STATS/streak")
    local solo_pct=0
    [[ $total -gt 0 ]] && solo_pct=$(( solo * 100 / total ))

    # Barra hacia 1000
    local filled=$(( total * 30 / 1000 ))
    [[ $filled -gt 30 ]] && filled=30
    local empty=$(( 30 - filled ))
    local bar="${GREEN}"
    for i in $(seq 1 $filled); do bar+="█"; done
    bar+="${DIM}"
    for i in $(seq 1 $empty); do bar+="░"; done
    bar+="${RESET}"

    # Meta mensual
    local month=$(date +%Y-%m)
    local month_count=$(grep "^$month" "$MOKA_STATS/log" 2>/dev/null | wc -l | tr -d ' ')
    local mfilled=$(( month_count * 20 / 150 ))
    [[ $mfilled -gt 20 ]] && mfilled=20
    local mempty=$(( 20 - mfilled ))
    local mbar="${CYAN}"
    for i in $(seq 1 $mfilled); do mbar+="█"; done
    mbar+="${DIM}"
    for i in $(seq 1 $mempty); do mbar+="░"; done
    mbar+="${RESET}"

    local sandbox_count=$(ls -d "$MOKA_SANDBOX"/*/ 2>/dev/null | wc -l | tr -d ' ')

    echo ""
    echo "${BOLD}${CYAN}  ☕  moka stats — coffeeMeitt${RESET}"
    echo "  ${DIM}codeforces.com/profile/coffeeMeitt${RESET}"
    echo ""
    echo "${BOLD}  Progreso total${RESET}  ${DIM}(meta: 1000)${RESET}"
    echo "  $bar  ${BOLD}$total${RESET}${DIM}/1000${RESET}"
    echo ""
    echo "  ${GREEN}Solo (hard):${RESET}     ${BOLD}$solo${RESET}  ${DIM}(${solo_pct}%)${RESET}"
    echo "  ${YELLOW}Con hint:${RESET}        ${BOLD}$hint${RESET}"
    echo "  ${CYAN}En sandbox:${RESET}      ${BOLD}$sandbox_count${RESET} problemas"
    echo ""
    echo "${BOLD}  Este mes${RESET}  ${DIM}(meta: 150)${RESET}"
    echo "  $mbar  ${BOLD}$month_count${RESET}${DIM}/150${RESET}  ${DIM}($(( month_count * 100 / 150 ))%)${RESET}"
    echo ""
    echo "  ${BOLD}Racha:${RESET}  ${MAGENTA}${BOLD}$streak días 🔥${RESET}"
    echo ""
}

# ─── moka log ────────────────────────────────────────────────────────────────
_moka_log() {
    _moka_init
    echo ""
    echo "${BOLD}${CYAN}  ☕  Historial (últimos 20)${RESET}"
    echo ""
    if [[ ! -s "$MOKA_STATS/log" ]]; then
        echo "  ${DIM}Vacío. Usa ${CYAN}moka done${DIM} para registrar problemas.${RESET}"
    else
        tail -20 "$MOKA_STATS/log" | while IFS= read -r line; do
            local d=$(echo $line | cut -d'|' -f1 | tr -d ' ')
            local n=$(echo $line | cut -d'|' -f2)
            local r=$(echo $line | cut -d'|' -f3 | tr -d ' ')
            if [[ "$r" == "solo" ]]; then
                printf "  ${DIM}%s${RESET}  ${GREEN}✓${RESET} ${BOLD}%s${RESET} ${DIM}(%s)${RESET}\n" "$d" "$n" "$r"
            else
                printf "  ${DIM}%s${RESET}  ${YELLOW}~${RESET} ${BOLD}%s${RESET} ${DIM}(%s)${RESET}\n" "$d" "$n" "$r"
            fi
        done
    fi
    echo ""
}

# ─── moka streak ─────────────────────────────────────────────────────────────
_moka_streak() {
    _moka_init
    local streak=$(cat "$MOKA_STATS/streak")
    local last=$(cat "$MOKA_STATS/last_date")
    echo ""
    echo "  ${MAGENTA}${BOLD}☕  $streak días de racha 🔥${RESET}"
    echo "  ${DIM}Último registro: $last${RESET}"
    echo ""
}

# ─── moka git ────────────────────────────────────────────────────────────────
_moka_git() {
    local curr=$(pwd)
    cd "$MOKA_ROOT"
    echo "${CYAN}  → git add .${RESET}"
    git add .
    echo -n "  Commit message (Enter = fecha automática): "
    read msg
    [[ -z "$msg" ]] && msg="solve: $(date +%Y-%m-%d)"
    git commit -m "$msg"
    git push
    echo "${GREEN}  ✓ Push exitoso${RESET}"
    cd "$curr"
}

# ─── Router ──────────────────────────────────────────────────────────────────
moka() {
    local cmd=$1
    shift
    case $cmd in
        go)      _moka_go "$@" ;;
        ls)      _moka_ls ;;
        new)     _moka_new "$@" ;;
        done)    _moka_done ;;
        log)     _moka_log ;;
        stats)   _moka_stats ;;
        streak)  _moka_streak ;;
        sandbox) _moka_sandbox "$@" ;;
        import)  _moka_import "$@" ;;
        git)     _moka_git ;;
        help|"") _moka_help ;;
        *)
            echo "${RED}  Error:${RESET} comando '${cmd}' no reconocido."
            echo "  Usa ${CYAN}moka help${RESET} para ver los comandos."
            ;;
    esac
}