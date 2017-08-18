#include <stdio.h>
#include <stdlib.h>

int main(int argc, char* argv[]){

        int nodes = atoi(argv[1]);
        int dbm = atoi(argv[2]);
        FILE* f;
        time_t t;
        int i,j,k;
        
        if(argc < 2){
        printf("Usage: topologizer nodes dbm\n");
                return -1;
        } else {
                f = fopen("topology.txt","w");
                k = 1;
                for(i = 1; i <= nodes; i++){
                        if(i%3 == 0) k++;
                        for(j = k; j <= nodes; j++){
                                if(i != j){
                                        fprintf(f,"%d %d -%d.0\n",i,j,dbm);
                                }
                        }
                        
                }
        }

}        
