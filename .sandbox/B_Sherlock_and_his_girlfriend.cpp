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

//si es un primo cambia el color 
/*
    solo necesito los factores primos de cada número 
    con una criba los puedo sacar

    puedo usar criba lineal? 
    podría, pero no me daría los divisores exactos
    con la de erastótenes si puedo cambiar el color de cada uno. 
    

    Lógica:
    Simplemente empiezo con 2, y voy subiendo, cada multiplo tendrá un color diferente


    10
    sólo los factores primos tienen que cambiar de color, todo lo demas lo puedo llenar con unos y ya.
    como los primos no tienen factores, no me afecta

    2 3 4 5 6 7 8 9 10

    1 1 2 

    1 2 3 4 5 6 7 8 9 10

    1 1 1 2 n 3 n 4 3 5
*/

vector<int> criba(int N) {
    N += 2;

    vector<int> criba(N, 0);
    vector<int> colors(N, 2);

    for(int i = 2; i < N; i++) {
        if(criba[i] == 0) {  //es primo
            //tachar los multiplos y agregarlo a los colores.

            //el color del primo es 1
            colors[i] = 1;

            //tachamos en la criba todos los multiplos
            for(int j = i; j < N; j += i) {
                criba[j] = 1;
            }
        }
    }

    return colors;
}


int32_t main() {
    fastio;
    
    int n;
    cin >> n;
    //cout << n << endl;

    
    if(n <= 2) {
        cout << 1 << endl;
    } else {
        cout << 2 << endl;
    }


    vector<int> ans = criba(n);

    n+= 2;
    for(int i = 2; i < n ; i++) {
        cout << ans[i] << " ";
    }
    cout << endl;
    
    return 0;
}