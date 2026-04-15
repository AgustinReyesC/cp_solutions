#include <bits/stdc++.h>
using namespace std;
 
#define fastio ios::sync_with_stdio(0); cin.tie(0); cout.tie(0)
#define all(x) (x).begin(), (x).end()
#define fi first
#define se second
typedef pair<int,int> pii;
 
const int INF = 1e9;
int n, m;
vector<string> g;
vector<vector<int>> dist, distM;
pii start;
vector<pii> dir = {{1,0},{-1,0},{0,1},{0,-1}};
vector<char> dirChar = {'D','U','R','L'};
 
 
 
 
 
int main(){
    fastio;
    cin >> n >> m;
    g.resize(n);
    for (auto &x : g) cin >> x;
 
    dist.assign(n, vector<int>(m, INF));
    distM.assign(n, vector<int>(m, INF));
 
 
 
    queue<pii> q;
    // BFS de monstruos
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            if(g[i][j]=='M'){
                q.push({i,j});
                distM[i][j]=0;
            }
            else if(g[i][j]=='A') start={i,j};
        }
    }
 
 
 
 
    while(!q.empty()){
        auto [x,y]=q.front(); q.pop();
 
        for(auto [dx,dy]:dir){
            int nx= x + dx;
            int ny= y + dy;
 
            if(nx>=0 && nx<n && ny>=0 && ny<m && g[nx][ny]!='#' && distM[nx][ny]==INF){
                distM[nx][ny]=distM[x][y]+1;
                q.push({nx,ny});
            }
        }
    }
 
 
 
    // BFS del jugador
    queue<pii> qa;
    qa.push(start);
    dist[start.fi][start.se]=0;
    vector<vector<char>> from(n, vector<char>(m,'?'));
 
    while(!qa.empty()){
        auto [x,y]=qa.front(); qa.pop();
 
        // si está en borde, puede escapar
        if(x==0 || x==n-1 || y==0 || y==m-1){
            string path="";
            while(!(x==start.fi && y==start.se)){
                char c = from[x][y];
                path.push_back(c);
                if(c=='U') x++;
                else if(c=='D') x--;
                else if(c=='L') y++;
                else if(c=='R') y--;
            }
            reverse(all(path));
            cout << "YES\n" << path.size() << "\n" << path << "\n";
            return 0;
        }
 
        for(int d=0; d<4; d++){
            int nx=x+dir[d].fi;
            int ny=y+dir[d].se;
 
            if(nx>=0 && nx<n && ny>=0 && ny<m && g[nx][ny]!='#' && dist[nx][ny]==INF){
                if(dist[x][y]+1 < distM[nx][ny]){ // solo si llegas antes que los monstruos
                    dist[nx][ny]=dist[x][y]+1;
                    from[nx][ny]=dirChar[d];
                    qa.push({nx,ny});
                }
            }
        }
    }
 
    cout << "NO\n";
}