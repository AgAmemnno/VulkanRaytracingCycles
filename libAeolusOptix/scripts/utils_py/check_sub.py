import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
DATA_OFFSET = 11
SUB = False
def bar(u,c):


    x = np.arange(len(u))  # the label locations
    width = 0.35  # the width of the bars

    fig, ax = plt.subplots()
    rects1 = ax.bar(u,c, width, label='subgroupID')
    print(f" max unique {np.max(u)} max count {np.max(c)}")
    """
    ax.set_ylabel('Scores')
    ax.set_title('Scores by group and gender')
    ax.set_xticks(x)
    ax.set_xticklabels(u)
    ax.legend()


    def autolabel(rects):
        "Attach a text label above each bar in *rects*, displaying its height."
        for rect in rects:
            height = rect.get_height()
            ax.annotate('{}'.format(height),
                        xy=(rect.get_x() + rect.get_width() / 2, height),
                        xytext=(0, 3),  # 3 points vertical offset
                        textcoords="offset points",
                        ha='center', va='bottom')


    autolabel(rects1)
    """

    fig.tight_layout()

    plt.show()
#301989888  303796224 326305152 (168856)  329192064 (188904)
def LEN_SET(d):
    d = np.array(d)
    print(f"  len  {len(d)}")
    unique, counts = np.unique(d, return_counts=True)
    counts.sort()
    #print(f" count {counts}")
    #print(f" count {unique}")
    bar(unique, counts)
    """
    sd = set(d)
    print(f"  set {len(sd)}")
    print(f"  {sd} ")
    hist, bin_edges = np.histogram(d)
    print(f"  hist  {hist}  bin {bin_edges} ")
    """
    return (unique,counts)




if SUB:
    #      sgid,gl_SubgroupInvocationID,block_idx
    fi         = "subgrooup.csv"
    df         = pd.read_csv(f"D:\\C\\Aeoluslibrary\\data\\profi\\{fi}", sep=',')#,header=None)
    d          = df.to_numpy()
    DATA       = 0
    OFFSET     = DATA + DATA_OFFSET
    D012       = d[:,OFFSET:OFFSET+3].astype("f")
    D345        = d[:,OFFSET+3:OFFSET+6].astype("f")
    d        = D345[:,0]
    print(d)
    temp = d.argsort()
    sgid = D012[temp,0]
    peak = D012[temp,1]
    blid = D012[temp,2]
    x = d[temp]
    line, = plt.plot(peak, color='blue', lw=2)
    plt.show()
    line, = plt.plot(blid, color='blue', lw=2)
    plt.show()
    line, = plt.plot(sgid, color='blue', lw=2)
    plt.show()
    
    print(sgid)
    D012       = d[:,OFFSET:OFFSET+3].astype("f")
    u,c        = LEN_SET(D012[:,0])
    u,c        = LEN_SET(D012[:,1])
    SG         = {}
    for i in range(len(D012)):
        d012        = D012[i,:]
        k = int(d012[0])
        if k not in SG:
            SG[k] = []
        SG[k].append(int(d012[1]))
    for (k,v) in SG.items():
        if 31 not in v:
            print(f" SG[{k}]    {v} ")

    """
    D345        = d[:,OFFSET+3:OFFSET+6].astype("f")
    for i in range(4):
        u,c = LEN_SET(vul[:,i])
        sd =  dict(zip(u, c))
        print(sd)
    """
