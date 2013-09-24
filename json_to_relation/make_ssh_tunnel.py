#!/usr/bin/env python
 
# http://pexpect.sourceforge.net/pexpect.html
# http://www.thescripts.com/forum/thread26248.html
 
import pexpect
import time
 
thetimeout = 2
port_lower = 4000
port_upper = 4050
 
def create (via_host, via_user, via_pwd, to_host, to_port):
    for via_port in range(port_lower, port_upper+1):
        cmd = 'ssh '+via_user+'@'+via_host+' -L '+str(via_port)+':'+to_host+':'+str(to_port)+' -N'
        child = pexpect.spawn(cmd, timeout=thetimeout)
        r = child.expect(['.ssword:*', 'Privileged ports can only be forwarded by root.*', pexpect.EOF, pexpect.TIMEOUT])
     
        if r == 0:
            time.sleep(0.1)
            child.sendline(via_pwd+'\n')
            r = child.expect(['bind: Address already in use.*local forwarding', pexpect.EOF, pexpect.TIMEOUT])
            
            if   r == 0 or r == 1:
                pass
            elif r == 2:
                return (child, via_port)
            else:
                print "Error: Unknown result from SSH tunneling attempt."
                pass
        else:
            print "Error: You are trying to open a privileged port as an unprivileged user."
    print "Error: Unable to bring up a tunnel within port range ["+str(port_lower)+","+str(port_upper)+"]."
    return (None, -1)
 
child, port = create("localhost", "tmp", "tmp", "google.com", 80)
print "port = "+str(port)
while (1):
    time.sleep(2)

