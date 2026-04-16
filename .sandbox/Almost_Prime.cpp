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

int32_t main() {
    fastio;
    
    int n;
    cin >> n;

    vector<int> prime(n+1, true);
    vector<int> nprimes(n+1, 0);

    for(int i = 2; i <= n; i++) {

        if(prime[i]) {
            //es primo
            for(int j = i; j <= n; j += i) {
                prime[j] = false;
                nprimes[j]++;
            }
        }
    }

    int ans = 0;
    for(int i = 0; i < nprimes.size(); i++) {
        if(nprimes[i] == 2) {
            ans++;
        }
    }
    
    cout << ans << endl;
    return 0;
}