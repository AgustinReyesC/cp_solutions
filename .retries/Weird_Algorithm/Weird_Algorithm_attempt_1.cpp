#include <algorithm>
#include <bits/stdc++.h>
#define int long long int
#define vi vector<int>
#define vvi vector<vector<int>>
#define vb vector<double>
#define vvb vector<vector<double>>
#define forN(n,v) for(int i=0;i<n;i++) cin>>v[i]
#define eraseU(v) v.erase(unique(v.begin(), v.end()), v.end())
#define umii unordered_map<int,int>
#define INFS 1e9
#define INFI -1e9
#define all(x) x.begin(), x.end()
#define pi pair<int,int>
#define ppi pair<pair<int,int>,int>
#define pb push_back
#define F first
#define S second
#define forEC(var, container) for( const auto& var: container)
#define forE(var, container) for( const auto& var: container)
const int MOD=1e9+7;
const int MAX6 = 1000005;
const int MAX5 = 100005;
const int M = 20;
using namespace std;
 
void solve(){
    int n; cin >> n;
    while(n != 1) {
        cout << n << " ";
        n = (n%2 == 0) ? n/2 : (n*3 + 1);
    }
    cout << 1 << endl;
}
 
int32_t main()
{
    // ios::sync_with_stdio(false);
    // cout.tie(nullptr);
    // cin.tie(nullptr);
    int T = 1;
    //cin>>T;
    while(T--) {
      solve();
    }
    return 0;
}