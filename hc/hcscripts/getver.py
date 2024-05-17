import sys
f=open('/tmp/pyver.txt','w')
tmp= sys.version
ver=tmp.split()
f.write(ver[0])
f.closed

