from os import system
import matplotlib.pyplot as plt

def ex():
    s = "kMeans_clang.exe"
    for k in range (64):    
        for size in range (32768):
            system(s+" "+str(size)+" "+str(k)+" "+str(20))
def disp():
    mini = 10000.0
    maxi = 0.0
    s = []
    k = []
    t = []
    
    sbis = []
    kbis = []
    tbis = []
    
    ster = []
    kter = []
    tter = []
    
    f = open("run_clang.txt", "r")
    # f.readline()
    for i in range(4096): 
        for a in range(1):
            s.append(0)
            k.append(0)
            t.append(0)
            # print(ik)
            line = f.readline()
            # for a in range(1):
            #     f.readline()
            # print(line.split(), end=' ')
            # print(i)
            s[i],k[i],t[i],dump = [float(v) for v in line.split()]

    # ax.scatter(s, k, t)

    for i in range(len(s)-1): 
        # print(t[i])
        mini = min(mini, t[i])
        maxi = max(maxi, t[i])
    for i in range(len(s)-1):
        if mini == t[i]:
            print("mini = {} {} {} {}".format(s[i], k[i], t[i], i))
    for i in range(len(s)-1):
        if maxi == t[i]:
            print("maxi = {} {} {}".format(s[i], k[i], t[i]))
    
    
    med = [0 for i in range(256)]
    for i in range(4096):
        med[int(s[i]/256-128)] = med[int(s[i]/256-128)] + t[i]
        # print(t[i])
    for i in range(256):
        med[i] = med[i] / 16
        # print("N = {} | {}".format( (i*256) + 128 ,med[i]))
    for i in range(4096):
        if k[i] < 24 and t[i] > 0.6*med[int(s[i]/256-128)] or s[i] > 4096:
            a = a
        else:
            sbis.append(s[i])
            kbis.append(k[i])
            tbis.append(t[i])
 
    for i in range(4096):
        if k[i] < 30 and t[i] > 0.75*med[int(s[i]/256-128)]:
            a = a
        else:
            ster.append(s[i])
            kter.append(k[i])
            tter.append(t[i])

    print("max in 0 - 4096 is {} ms".format(tbis[len(tbis)-1]))
    fig = plt.figure()
    ax = fig.add_subplot(111, projection='3d')
    ax.plot_trisurf(s, k, t, cmap=plt.cm.CMRmap)
    ax.set_title("TEMPS EXEC ALL")
    
    fig2 = plt.figure()
    ax2 = fig2.add_subplot(111, projection='3d')
    ax2.plot_trisurf(sbis, kbis, tbis, cmap=plt.cm.CMRmap)
    ax2.set_title("TEMPS EXEC < 4096 pixel lisse")

    fig3 = plt.figure()
    ax3 = fig3.add_subplot(111, projection='3d')
    ax3.plot_trisurf(ster, kter, tter, cmap=plt.cm.CMRmap)
    ax3.set_title("TEMPS EXEC lisse")
    plt.show()
disp()