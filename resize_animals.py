import os
from PIL import Image

def create_icons(input_folder, output_folder, canvas_size=1024, icon_size=(300, 300)):
    os.makedirs(output_folder, exist_ok=True)

    for filename in os.listdir(input_folder):
        if filename.lower().endswith(".png"):
            img_path = os.path.join(input_folder, filename)
            img = Image.open(img_path).convert("RGBA")

            # Maak vierkante transparante canvas
            square = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
            img.thumbnail((canvas_size, canvas_size), Image.LANCZOS)

            x = (canvas_size - img.width) // 2
            y = (canvas_size - img.height) // 2
            square.paste(img, (x, y), img)

            # Resize naar icon formaat
            final = square.resize(icon_size, Image.LANCZOS)

            output_path = os.path.join(output_folder, filename)
            final.save(output_path)

            print(f"Processed: {filename}")

    print(f"Done processing {input_folder}")



def create_silhouette_icons(input_folder, output_folder, canvas_size=1024, icon_size=(300, 300)):
    """Create dark silhouette versions of animal icons for the map"""
    os.makedirs(output_folder, exist_ok=True)

    for filename in os.listdir(input_folder):
        if filename.lower().endswith(".png"):
            img_path = os.path.join(input_folder, filename)
            img = Image.open(img_path).convert("RGBA")

            # Get the alpha channel (the shape of the animal)
            r, g, b, a = img.split()
            
            # Create dark silhouette color (51, 51, 51 = #333333) with same size
            dark_color = Image.new("RGBA", img.size, (51, 51, 51, 255))
            
            # Use the original alpha as the alpha for the dark color
            # This makes only the visible parts of the animal dark
            silhouette = Image.merge("RGBA", (
                Image.new("L", img.size, 51),  # R channel - dark gray
                Image.new("L", img.size, 51),  # G channel - dark gray
                Image.new("L", img.size, 51),  # B channel - dark gray
                a  # Use original alpha
            ))
            
            # Create square canvas
            square = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
            silhouette.thumbnail((canvas_size, canvas_size), Image.LANCZOS)

            x = (canvas_size - silhouette.width) // 2
            y = (canvas_size - silhouette.height) // 2
            square.paste(silhouette, (x, y), silhouette)

            # Resize to icon format
            final = square.resize(icon_size, Image.LANCZOS)

            output_path = os.path.join(output_folder, filename)
            final.save(output_path)

            print(f"Created silhouette: {filename}")

    print(f"Done creating silhouettes for {input_folder}")


# 🔥 Animals
create_icons(
    "assets/animals/master",
    "assets/animals/icons_300"
)

# 🔥 Animals - Create silhouette versions for map display
create_silhouette_icons(
    "assets/animals/master",
    "assets/animals/icons_300_silhouette"
)

# 🔥 Seeds
create_icons(
    "assets/seeds/master",
    "assets/seeds/icons_300"
)

# 🔥 Fruits (harvest icons)
create_icons(
    "assets/fruits/master",
    "assets/fruits/icons_300"
)
