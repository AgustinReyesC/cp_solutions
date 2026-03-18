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

void floyd_warshall(int &n) {

    for(int k = 1; k <= n; k++) {
        for(int i = 1; i <= n; i++) {
            for(int j = 1; j <= n; j++) {

                if(g[i][k] != LLONG_MAX && g[k][j] != LLONG_MAX && g[i][j] > g[i][k] + g[k][j]) {
                    g[i][j] = g[i][k] + g[k][j];
                }

            }
        }
    }


}


int32_t main() {
    fastio;
    
    int n, m, q;
    cin >> n >> m >> q;

    g.assign(n+1, vi(n+1, LLONG_MAX));
    for(int i = 1; i <= n; i++) {
        g[i][i] = 0;
    }


    while(m--) {
        int x, y, w;
        cin >> x >> y >> w;
        g[x][y] = min(g[x][y], w);
        g[y][x] = min(g[y][x], w);
    }

    floyd_warshall(n);
    while(q--) {
        int from, to;
        cin >> from >> to;
        cout << (g[from][to] != LLONG_MAX ? g[from][to] : -1) << endl;
    }

    return 0;
}