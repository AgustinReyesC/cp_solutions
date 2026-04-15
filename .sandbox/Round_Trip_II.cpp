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
stack<int> path;
vi res;

bool dfs(int cur) {
    vis[cur] = 1;
    path.push(cur);

    for(auto y : g[cur]) {
        if(!vis[y]) {
            if(dfs(y)) return true; ;
        } else {
            res.push_back(y);

            while(!path.empty()) {
                res.push_back(path.top());
                path.pop();
            }
            
            return true;
        }
    }

    path.pop();
    vis[cur] = 0;
    return false;
}


int32_t main() {
    fastio;

    int n, m;
    cin >> n >> m;

    g.assign(n+1, {});
    for(int i = 0; i < m; i++) {
        int x, y;
        cin >> x >> y;
        g[x].push_back(y);
    }

    bool found = false;
    for(int i = 1; i <= n && !found; i++) {
        if(dfs(i)) found = true;
    }
    

    if(res.size() == 0) {
        cout << "IMPOSSIBLE" << endl;
        return 0;
    }

    cout << res.size() << endl;
    for(int i = res.size()-1; i >= 0; i--) {
        cout << res[i] << " ";
    }
    
    return 0;
}