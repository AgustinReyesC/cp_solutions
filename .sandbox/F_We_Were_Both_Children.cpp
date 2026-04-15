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


/*
    Si los divisores de mi celda pueden formar los divisores de las demás, entonces puedo llegar dessde la otra posición hasta esa.

    //se puede brutforcear
    brincando y poniendo 1 en cada brinco. cada brinco obtiene el número mayor de ranas.
    100 test cases
    200000 ranas
    saltos de hasta 1 000 000 000.
*/

void solve() {
    int n;
    cin >> n;

    vi cnt(n+1, 0);
    vi best_trap(n+1, 0);
    int frog;

    for(int i = 0; i < n; i++) {
        int a; cin >> a;
        if(a <= n) cnt[a]++;
    }

    for(int a = 1; a <= n; a++) {
        if(cnt[a] == 0) continue;
        for(int temp = a; temp <= n; temp += a) {
            best_trap[temp] += cnt[a];
        }
    }

    cout << *max_element(all(best_trap)) << endl;
    return;
}

int32_t main() {
    fastio;

    int t;
    cin >> t;
    while(t--) {
        solve();
    }  
    return 0;
}