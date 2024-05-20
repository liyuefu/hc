import sys

if len(sys.argv) > 1:
    TMPDIR = sys.argv[1]
else:
    TMPDIR = '/tmp'
FILE = TMPDIR + "/pyver.txt"
f=open(FILE,'w')
tmp= sys.version
ver=tmp.split()
f.write(ver[0])
f.closed

