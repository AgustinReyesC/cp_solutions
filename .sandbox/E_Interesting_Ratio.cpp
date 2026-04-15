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
    cómo puedo hacer que una división me de un número primo?
    Si el numero de arriba es el mismo que abajo multiplicado por un primo


    ahora, pensandolo al reves,
    puedo construir un número que dividido entre otro sea primo con sus divisores.
    pero cómo se que que hay dos numeros tal que lcm(a, b) = num1 y gcd(a, b) = num2?

    solo es encontrar los primos de 1 a p 
    y luego1 si los dos numeros son g y g*p, los numeros validos para cada p son hasta n/p


    //primero cuento el numero de primos

    tengo que encontrar el numero de primos hasta cada numero
    luego para cada primo hago n/p y eso me da las combinaciones
*/

const int constraint = 1e7+1;
vi sieve(constraint, 0);

void do_sieve() {
    for(int i = 2; i < constraint; i++) {
        if(sieve[i] == 0) {
            //primo
            for(int t = i * 2; t < constraint; t += i) {
                sieve[t] = 1;
            }
        }
    }
}


void solve() {
    int n;
    cin >> n;

    int ans = 0;
    for(int i = 2; i <= n; i++ ) {
        if(sieve[i] == 0) {
            //es primo
            //tengo que sumar n / p
            ans += n / i;
        }
    }

    cout << ans << endl;
    return;
}


int32_t main() {
    fastio;
    do_sieve();
    
    int t;
    cin >> t;
    while(t--) {
        solve();
    }
    return 0;
}