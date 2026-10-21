import os,sys
from PIL import Image
sp, out = sys.argv[1], sys.argv[2]
sel = {
 'wanderlog':[7,5,6,10],'tripit':[3,2,4],'howbout':[3,5,4,2],'partiful':[3,9,6,7],
 'splitwise':[1,2,3,4],'tricount':[3,4,5,7],'settleup':[3,8,9],'tab':[1,4,6],'splid':[1,3,5],'venmo':[7,6,1],
}
for app,ids in sel.items():
    for i in ids:
        im=Image.open(f'{sp}/shots/{app}_{i:02d}.jpg').convert('RGB')
        w=440; im=im.resize((w,int(im.height*w/im.width)),Image.LANCZOS)
        im.save(f'{out}/img/{app}_{i:02d}.jpg',quality=80,optimize=True,progressive=True)
web={'wa_poll_01.jpg':'whatsapp_poll_create.jpg','wa_poll_02.jpg':'whatsapp_poll_notify.jpg','imsg_poll_03.jpg':'imessage_poll.jpg'}
for src,dst in web.items():
    im=Image.open(f'{sp}/shots_web/{src}').convert('RGB')
    w=620 if 'whatsapp' in dst else 440
    im=im.resize((w,int(im.height*w/im.width)),Image.LANCZOS)
    im.save(f'{out}/img/{dst}',quality=82,optimize=True,progressive=True)
print(len(os.listdir(f'{out}/img')))
