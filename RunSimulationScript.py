print "********************************************";
print "*                                          *";
print "*             TOSSIM Script                *";
print "*                                          *";
print "********************************************";

import sys;
import time;
import random;

from TOSSIM import *;

t = Tossim([]);


topofile="15-15-tight-mica2-grid.txt";  # load topology
#topofile="topology.txt";
modelfile="meyer-heavy.txt"; # and model


print "Initializing mac....";
mac = t.mac();
print "Initializing radio channels....";
radio=t.radio();
print "    using topology file:",topofile;
print "    using noise file:",modelfile;
print "Initializing simulator....";
t.init();


outfile = "share/simulation4.csv"; 
out = sys.stdout;
csv = open(outfile, 'a');

#Add debug channel
print "Activate debug message on channel init"
t.addChannel("init",out);
print "Activate debug message on channel boot"
t.addChannel("boot",out);
print "Activate debug message on channel radio"
t.addChannel("radio",out);
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
#t.addChannel("csv", csv);
t.addChannel("relay_resp", out);

numNodes = 10; #set the number of nodes. NOTE: change this value also in DataCollection

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
        elif(s[0] != 'noise'):
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

for i in range(0,500000):
        t.runNextEvent()
	
print >>out, "\n\n\n[TOSSIM]Simulation finished!";


