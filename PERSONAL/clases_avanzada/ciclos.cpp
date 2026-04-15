#include <bits/stdc++.h>
using namespace std;

#define fastio ios::sync_with_stdio(0); cin.tie(0); cout.tie(0)
#define all(x) (x).begin(), (x).end()
#define rall(x) (x).rbegin(), (x).rend()
#define pb push_back
#define fi first
#define se second
#define int long long int

typedef long long ll;
typedef pair<int, int> pii;
typedef pair<ll, ll> pll;
typedef vector<int> vi;
typedef vector<ll> vll;
typedef vector<pii> vpii;
typedef vector<pll> vpll;
typedef vector<vi> vvi;
typedef vector<vll> vvll;

const int INF = 1e9 + 7;
const ll LINF = 1e18;
const double EPS = 1e-9;
const double PI = acos(-1);

vvi g;
vi vis, inStack;
int n, m;

//grafo no dirigido
//pregunta: Ya lo visité? Es un nodo diferente a mi padre?
bool undir_graph(int current, int parent) {
    vis[current] = true;

    for(int adyacente : g[current]) {
        if(!vis[adyacente]) {
            //si adentro tengo un ciclo, ya directamente retorno true
            if(undir_graph(adyacente, current)) return true;
        }
        else if(parent != adyacente) {
            return true;
        }
    }

    return false;
}

//grafo dirigido
//pregunta: Ya lo visité? El nodo está ya en mi recorrido?
bool dir_graph(int current){
    vis[current] = true; 
    inStack[current] = true;

    for(int adyacente : g[current]) {
        if(!vis[adyacente]) {
            if(dir_graph(adyacente)) return true;
        } else if(inStack[adyacente]) {
            return true; //está en mi recorrido
        }
    }

    inStack[current] = false; //lo elimina del recorrido
    return false;
}

void solve() {
    g.clear();
    vis.clear();
    inStack.clear();

    cin >> n >> m;

    g.resize(n + 1);
    vis.resize(n + 1, false);
    inStack.resize(n+1, false);


    int opc;
    cout << "dir(1), undir(2): " << endl;
    cin >> opc;

    for(int i = 0; i < m; i++) {
        int x, y;
        cin >> x >> y;
        g[x].push_back(y);
        if(opc == 2) {
            g[y].push_back(x);
        }
    }

    if((opc == 2 && undir_graph(1, 1))|| (opc == 1 && dir_graph(1))) {
        cout << "CICLO DETECTADO" << endl;
    } else {
        cout << "CICLO NO DETECTADO" << endl;
    }
}

int32_t main() {
    fastio;
    //freopen("Test/input_1.txt", "r", stdin);
    int t = 1;
    cin >> t;

    while(t--) {
        solve();
    }
    
    
    return 0;
}