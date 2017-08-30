print "********************************************";
print "*                                          *";
print "*             TOSSIM Script                *";
print "*                                          *";
print "********************************************";

import sys;
import time;
import random;

from tinyos.tossim.TossimApp import *
from TOSSIM import *

n = NescApp()
t = Tossim(n.variables.variables())
m = t.getNode(1)

numNodes = 10; #set the number of nodes. NOTE: change this value also in DataCollection

# load topology
topologies = ["GRID-36-3m.txt",\
                "GRID-36-10m.txt",\
                "GRID-100-3m.txt",\
                "GRID-100-4m.txt",\
                "GRID-225-3m.txt",\
                "GRID-400-3m.txt",\
                "15-15-UNIFORM-36.txt",\
                "15-15-UNIFORM-100.txt",\
                "30-30-UNIFORM-400.txt",\
                "15-15-RANDOM-36.txt",\
                "15-15-RANDOM-100.txt",\
                "30-30-RANDOM-400.txt",\
                "simpleTopology.txt"] #12

topo = topologies[12];

topofile = "support/" + topo;

# and model
modelfile="meyer-heavy.txt"; #casino-lab.txt


print "Initializing mac....";
mac = t.mac();
print "Initializing radio channels....";
radio=t.radio();
print "    using topology file:",topofile;
print "    using noise file:",modelfile;
print "Initializing simulator....";
t.init();


out = sys.stdout;
csv = open("share/" + topo.split('.')[0] + ".csv", 'w');
pkt_csv = open("share/" + topo.split('.')[0] + "-packets.csv", "w")

#Add debug channel
print "Activate debug message on channel init"
#t.addChannel("init",out);
print "Activate debug message on channel boot"
#t.addChannel("boot",out);
print "Activate debug message on channel radio"
#t.addChannel("radio",out);
print "Activate debug message on channel radio_send"
#t.addChannel("radio_send",out);
print "Activate debug message on channel radio_ack"
#t.addChannel("radio_ack",out);
print "Activate debug message on channel radio_rec"
#t.addChannel("radio_rec",out);
print "Activate debug message on channel radio_pack"
#t.addChannel("radio_pack",out);
print "Activate debug message on channel role"
#t.addChannel("role",out);
print "Activate debug message on channel nex_hop"
#t.addChannel("next_hop",out);
print "Activate debug message on channel sink"
t.addChannel("sink",out);
print "Activate debug message on channel radio_error"
t.addChannel("radio_error",out);
t.addChannel("csv", csv);
#t.addChannel("relay_resp", out);
t.addChannel("packets_csv", pkt_csv);


nodes = [];

#node creation and boot
for x in range(1,numNodes+1):
        nodes.insert(x-1,t.getNode(x));
        boot_time = random.randint(0,5) * t.ticksPerSecond();
        nodes[x-1].bootAtTime(boot_time);
        print >>out,"Creating node ",x,"...Will boot at ",boot_time/t.ticksPerSecond(), "[sec]";  



print >>out,"Creating radio channels..."
f = open(topofile, "r");
lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
        if(s[0] == 'gain'):
            radio.add(int(s[1]), int(s[2]), float(s[3]))
        elif(s[0] != 'noise'): #this is to manage topologies of type <src dest gain>
            radio.add(int(s[0]), int(s[1]), float(s[2]))

#Creazione del modello di canale
print >>out,"Initializing Closest Pattern Matching (CPM)...";
noise = open(modelfile, "r")
lines = noise.readlines()
compl = 0;
mid_compl = 0;

print >>out,"Reading noise model data file:", modelfile;
print >>out,"Loading:",
for line in lines:
    str = line.strip()
    if (str != "") and ( compl < 10000 ):
        val = int(str)
        mid_compl = mid_compl + 1;
        if ( mid_compl > 5000 ):
            compl = compl + mid_compl;
            mid_compl = 0;
            sys.stdout.write ("#")
            sys.stdout.flush()
        for i in range(1, numNodes+1):
            t.getNode(i).addNoiseTraceReading(val)
print >>out,"Done!";

#create noise model
for i in range(1, numNodes+1):
    t.getNode(i).createNoiseModel()

print >>out,"[TOSSIM] Start simulation with TOSSIM! \n\n\n";

counter = m.getVariable("DataCollectionC.last_counter")
while counter.getData() <= 50:
        t.runNextEvent()
        counter = m.getVariable("DataCollectionC.last_counter")
	
print >>out, "\n\n\n[TOSSIM]Simulation finished!";


