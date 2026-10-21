import json,re,sys,os,urllib.request
lookup, out = sys.argv[1], sys.argv[2]
slug = {1476732439:'wanderlog',311035142:'tripit',947925763:'polarsteps',310633997:'whatsapp',1662982304:'partiful',1477248221:'howbout',458023433:'splitwise',349866256:'tricount',991473495:'splid',737534985:'settleup',351727428:'venmo',932493382:'revolut',595068606:'tab'}
d=json.load(open(lookup))
for r in d['results']:
    s=slug[r['trackId']]
    for i,u in enumerate(r['screenshotUrls'],1):
        u2=re.sub(r'/[^/]+$','/600x0w.jpg',u)
        p=os.path.join(out,f'{s}_{i:02d}.jpg')
        urllib.request.urlretrieve(u2,p)
    print(s,len(r['screenshotUrls']))
