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

vector<vector<pair<int, int>>> g;

int32_t main() {
    fastio;
    
    int n, m;
    cin >> n >> m;
    g.assign(n+1, {});

    while(m--) {
        int x, y, w;
        cin >> x >> y >> w;
        g[x].push_back({y, w});
    }

    //w, to
    priority_queue<pair<int, int>, vector<pair<int, int>>, greater<pair<int, int>>> q;

    vector<int> low_dist(n+1, LLONG_MAX);

    q.push({0, 1});
    while(!q.empty()) {
        auto [w, from] = q.top();
        q.pop();

        if(low_dist[from] < w) continue;
        low_dist[from] = w;

        for(auto [yto, wto] : g[from]) {
            if(w + wto < low_dist[yto]) {
                low_dist[yto] = w + wto;
                q.push({w + wto, yto});
            }
        }
    }
    
    for(int i = 1; i <= n; i++) {
        cout << low_dist[i] << " ";
    }


    //comentario fijado para retry

    return 0;
}