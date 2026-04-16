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

//nomas saco los primos de 1 a 500000 y los pusheo y ya
const int N = 1e5;


int32_t main() {
    fastio;

    //criba
    vi is_prime(N+1, true);
    vi primes;

    for(int i = 2; i <= N; i++) {
        if(is_prime[i]) {
            primes.push_back(i);
            for(int j = i*2; j <= N; j += i) {
                is_prime[j] = false;
            }
        }
    }

    int n;
    cin >> n;

    cout << primes[n-1] << endl;  
    
    return 0;
}