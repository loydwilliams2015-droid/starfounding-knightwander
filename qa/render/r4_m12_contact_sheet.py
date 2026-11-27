#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json
root=Path(__file__).resolve().parent.parent
source=root/'captures/r4_m12_engine'
paths=sorted(x for x in source.glob('*.png') if x.name[0].isdigit())
assert len(paths)==12, f'Expected 12 real native captures, got {len(paths)}'
thumb_w,thumb_h=480,270
spacing=12
label_h=26
cols,rows=3,4
W=cols*thumb_w+(cols+1)*spacing
H=rows*(thumb_h+label_h)+(rows+1)*spacing
sheet=Image.new('RGB',(W,H),'#152534')
draw=ImageDraw.Draw(sheet)
try:font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',13)
except OSError:font=ImageFont.load_default()
for k,p in enumerate(paths):
    image=Image.open(p).convert('RGB')
    assert image.size==(960,540)
    x=spacing+(k%cols)*(thumb_w+spacing)
    y=spacing+(k//cols)*(thumb_h+label_h+spacing)
    sheet.paste(image.resize((thumb_w,thumb_h),Image.Resampling.LANCZOS),(x,y))
    caption=p.stem[3:].replace('_',' ')
    draw.text((x+5,y+thumb_h+5),f'{k+1:02d}  {caption}',fill='#e6f4ed',font=font)
contact=source/'R4_M12_TWELVE_FRAME_NATIVE_REVIEW.png'
sheet.save(contact,optimize=True)
items=["02_pad05_v2_pending.png","03_pad05_ack_sink.png","05_pad11_fault_compensated.png","06_pad11_sink_delivered.png","09_airborne_not_saved.png","10_recovered_checkpoint.png"]
comparison=Image.new('RGB',(960,3*540),'#152534')
for i in range(3):
    a=Image.open(source/items[2*i]).convert('RGB').resize((480,270))
    b=Image.open(source/items[2*i+1]).convert('RGB').resize((480,270))
    # 960×540 canvas, two full-height halves with original 960×540 source scaled and centered.
    for j,img in enumerate([a,b]):comparison.paste(img,(j*480,i*540+120))
compare=source/'R4_M12_PENDING_COMPENSATED_RECOVERED.png'
comparison.save(compare,optimize=True)
print('R4_M12_SHEET captures=',len(paths),'review=',contact.name,'comparison=',compare.name)
