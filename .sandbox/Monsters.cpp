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

vector<vector<char>> g;
vpii dir = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}};
vector<char> dirc = {'D', 'U', 'R', 'L'};

bool contains(int &n, int &m, int &x, int &y) {
    return x >= 0 && y >= 0 && x < n && y < m;
}

int32_t main() {
    fastio;
    
    int n, m;
    cin >> n >> m;
    g.assign(n, vector<char>(m, ' '));

    queue<pair<int, int>> monsters;
    vvi steps(n, vi(m, LINF));
    vvi vis(n, vi(m, 0));
    int ia, ja;


    for(int i = 0; i < n; i++) {
        string s;
        cin >> s;
        g[i] = vector<char>(s.begin(), s.end());

        for(int j = 0; j < m; j++) {
            if(g[i][j] == 'M') {
                monsters.push({i, j});
                steps[i][j] = 0;
            }
            else if(g[i][j] == 'A') {
                ia = i;
                ja = j;
            }
        }
    }

    //bfs monsters
    while(!monsters.empty()) {
        auto [x, y] = monsters.front(); monsters.pop();
        vis[x][y] = 1;

        for(auto [xdir, ydir] : dir) {
            int xnew = x + xdir;
            int ynew = y + ydir;

            if(contains(n, m, xnew, ynew) && !vis[xnew][ynew] && steps[x][y] + 1 < steps[xnew][ynew] && g[xnew][ynew] != '#') {
                vis[xnew][ynew] = 1;
                steps[xnew][ynew] = steps[x][y] + 1;
                monsters.push({xnew, ynew});
            }
        }
    }

    //aquí ya calculamos steps.
    //falta recorrer el camino a ver si puedo lleghar a una esquina antes
    //limpio visita y hago dfs con path
    vis.assign(n, vi(m, 0));
    pair<int, int> end_cell;

    for(int i = 0; i < n; i++) {
        if()    
    }

    
}