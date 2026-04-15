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
vi vis;
int n, m;

bool bfs(int src, int dest) {
    vis.assign(n+1, 0);
    vis[src] = 1;

    queue<int> q;
    q.push(src);

    while(!q.empty()) {
        int cur = q.front(); q.pop();
        vis[cur] = 1;

        for(auto y : g[cur]) {
            if(!vis[y]) q.push(y);
            if(y == dest) return true;
        }
    }

    return false;
}

int bellman_ford(vector<tuple<int, int, int>>& edges, vector<int>& g_weights) {
    for(int i = 1; i <= n; i++) {
        for(int j = 0; j < m; j++) {
            auto [x, y, w] = edges[j];
            if(g_weights[x] != LLONG_MAX && g_weights[x] + w < g_weights[y]) {
                g_weights[y] = g_weights[x] + w;
            }
        }
    }

    for(int j = 0; j < m; j++) {
        auto [x, y, w] = edges[j];
        if(g_weights[x] != LLONG_MAX && g_weights[x] + w < g_weights[y]) {
            if(bfs(y, n)) return -1;
        }
    }

    return -g_weights[n];
}

int32_t main() {
    fastio;
    
    cin >> n >> m;

    g.assign(n+1, {});
    vector<int> g_weights(n+1, LLONG_MAX);
    g_weights[1] = 0;

    vector<tuple<int, int, int>> edges;

    for(int i = 0; i < m; i++) {
        int x, y, w;
        cin >> x >> y >> w;
        g[x].push_back(y);
        edges.push_back({x, y, -w});
    }

    cout << bellman_ford(edges, g_weights) << endl;
    return 0;
}