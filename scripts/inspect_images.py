from PIL import Image
paths=[r"g:/samui_quest/assets/quest_bronze.png",r"g:/samui_quest/assets/quest_silver.png",r"g:/samui_quest/assets/quest_gold.png"]
for p in paths:
    try:
        img=Image.open(p)
        print(p, img.size)
    except Exception as e:
        print('error', p, e)