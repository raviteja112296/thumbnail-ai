# import os
# import base64
# import io
# import json
# import requests
# from PIL import Image
# from dotenv import load_dotenv

# load_dotenv()

# API_KEY = os.getenv('GEMINI_API_KEY')

# # Gemini 2.5 Pro can generate images
# GEMINI_MODEL = "gemini-2.5-pro"
# GEMINI_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"

# print(f"[GEMINI] Initialized with {GEMINI_MODEL}")


# # ═══════════════════════════════════════════════════════════════════════════════
# # Main entry point
# # ═══════════════════════════════════════════════════════════════════════════════

# def generate_thumbnail(prompt: str, images: list, user_id: str) -> dict:
#     print(f"\n{'='*60}")
#     print(f"[GEMINI] Starting generation for: '{prompt[:80]}'")
#     print(f"[GEMINI] Images received: {len(images)}")

#     # ── Process images ────────────────────────────────────────────────────────
#     image_data = []

#     for i, img_file in enumerate(images):
#         try:
#             img_file.seek(0)
#             img_bytes = img_file.read()
#             pil = Image.open(io.BytesIO(img_bytes))

#             # Convert to RGB
#             if pil.mode in ('RGBA', 'P', 'LA'):
#                 bg = Image.new('RGB', pil.size, (255, 255, 255))
#                 if pil.mode == 'P':
#                     pil = pil.convert('RGBA')
#                 bg.paste(pil, mask=pil.split()[-1] if pil.mode in ('RGBA', 'LA') else None)
#                 pil = bg
#             elif pil.mode != 'RGB':
#                 pil = pil.convert('RGB')

#             # Keep high res — max 1500px
#             if max(pil.size) > 1500:
#                 pil.thumbnail((1500, 1500), Image.LANCZOS)

#             buf = io.BytesIO()
#             pil.save(buf, format='JPEG', quality=92)
#             buf.seek(0)
            
#             # Convert to base64
#             b64 = base64.b64encode(buf.getvalue()).decode('utf-8')
#             image_data.append(b64)
#             print(f"[GEMINI] Image {i+1} prepared: {pil.size}")

#         except Exception as e:
#             print(f"[GEMINI] Image {i+1} failed: {e}")
#             continue

#     if not image_data:
#         return {
#             'success': False,
#             'has_image': False,
#             'error': 'No valid images could be processed',
#             'user_id': user_id
#         }

#     # ── Build thumbnail prompt ────────────────────────────────────────────────
#     thumbnail_prompt = f"""You are a world-class YouTube thumbnail designer with image generation abilities.

# INSTRUCTIONS:
# 1. Look at the uploaded image(s) - use the person's face and appearance as reference
# 2. Understand the topic: "{prompt}"
# 3. Generate a complete 1280x720 YouTube thumbnail image with:

# DESIGN ELEMENTS:
# - PERSON: Large and dominant on the LEFT side (40% of frame)
#   * Use the uploaded person's face/appearance
#   * Match their expression to the topic emotion (urgent/excited/shocked/serious)
#   * Add a bright glowing outline to make them POP
  
# - TEXT: Bold and readable on the RIGHT side (remaining 60%)
#   * Maximum 2 lines
#   * High contrast (white text with dark shadow or outline)
#   * Topic-related keywords
#   * Readable even at thumbnail size
  
# - BACKGROUND: Cinematic quality
#   * Directly related to the topic: "{prompt}"
#   * Dramatic lighting
#   * High quality, professional
  
# - COLORS: Eye-catching and dramatic
#   * High contrast
#   * Match the emotional tone (red for urgency, blue for calm, orange for excitement)
  
# - DECORATIONS: Add relevant graphics
#   * News: alert icons, warning symbols, red accents
#   * Flood/Disaster: water effects, emergency colors, lightning
#   * Tutorial: arrows, checkmarks, numbers
#   * Use emojis or simple icons
  
# COMPOSITION RULES:
# - 16:9 aspect ratio (1280x720 exactly)
# - No text cut off at edges
# - Person on left, content on right
# - Dark overlay on text area for readability
# - Professional, clean design

# GENERATE THIS IMAGE NOW."""

#     # ── Call Gemini 2.5 Pro with image generation ─────────────────────────────
#     print(f"[GEMINI] Calling {GEMINI_MODEL}...")
    
#     try:
#         payload = {
#             "contents": [
#                 {
#                     "parts": [
#                         # Add uploaded images as reference
#                         *[
#                             {
#                                 "inline_data": {
#                                     "mime_type": "image/jpeg",
#                                     "data": img
#                                 }
#                             }
#                             for img in image_data
#                         ],
#                         # Add the prompt
#                         {
#                             "text": thumbnail_prompt
#                         }
#                     ]
#                 }
#             ],
#             "generationConfig": {
#                 "temperature": 1.0,
#             }
#         }
        
#         response = requests.post(
#             f"{GEMINI_URL}?key={API_KEY}",
#             json=payload,
#             headers={"Content-Type": "application/json"},
#             timeout=120
#         )

#         print(f"[GEMINI] Status: {response.status_code}")

#         if response.status_code != 200:
#             print(f"[GEMINI] Response text: {response.text[:200]}")
#             try:
#                 error_data = response.json()
#                 error_msg = error_data.get('error', {}).get('message', str(error_data))
#             except:
#                 error_msg = response.text[:200]
            
#             print(f"[GEMINI] Error: {error_msg}")
#             return {
#                 'success': False,
#                 'has_image': False,
#                 'error': error_msg,
#                 'user_id': user_id
#             }

#         result = response.json()
#         print(f"[GEMINI] Response received, checking for image...")

#         # ── Extract image from response ───────────────────────────────────────
#         if 'candidates' in result and len(result['candidates']) > 0:
#             candidate = result['candidates'][0]
            
#             if 'content' in candidate and 'parts' in candidate['content']:
#                 parts = candidate['content']['parts']
#                 print(f"[GEMINI] Found {len(parts)} parts in response")
                
#                 for i, part in enumerate(parts):
#                     print(f"[GEMINI] Part {i}: {list(part.keys())}")
                    
#                     # Check for image data
#                     if 'inline_data' in part:
#                         data = part['inline_data']
#                         mime = data.get('mime_type', 'unknown')
                        
#                         # Check if it's an image
#                         if 'image' in mime:
#                             b64 = data.get('data', '')
#                             if b64:
#                                 print(f"[GEMINI] ✅ Found image — {mime}, {len(b64)//1024}KB")
#                                 print('='*60)
                                
#                                 return {
#                                     'success': True,
#                                     'has_image': True,
#                                     'image_base64': b64,
#                                     'description': f'{GEMINI_MODEL} | {prompt[:60]}',
#                                     'user_id': user_id
#                                 }
                    
#                     # Check for text (might contain base64 image)
#                     if 'text' in part:
#                         text = part['text']
#                         print(f"[GEMINI] Text response (first 100 chars): {text[:100]}")

#         print(f"[GEMINI] No image found in response")
#         print(f"[GEMINI] Full response keys: {list(result.keys())}")
        
#         return {
#             'success': False,
#             'has_image': False,
#             'error': 'Model did not return an image',
#             'user_id': user_id,
#             'debug': str(result)[:200]
#         }

#     except requests.exceptions.Timeout:
#         msg = 'Request timeout — image generation took too long'
#         print(f"[GEMINI] {msg}")
#         return {
#             'success': False,
#             'has_image': False,
#             'error': msg,
#             'user_id': user_id
#         }

#     except Exception as e:
#         error_msg = str(e)
#         print(f"[GEMINI] Exception: {error_msg}")
#         import traceback
#         traceback.print_exc()

#         if '429' in error_msg or 'quota' in error_msg.lower():
#             msg = 'Quota exceeded — wait or upgrade your quota'
#         elif 'safety' in error_msg.lower() or 'blocked' in error_msg.lower():
#             msg = 'Content blocked by safety filter — try a different prompt'
#         elif 'api_key' in error_msg.lower() or '403' in error_msg:
#             msg = 'Invalid API key'
#         else:
#             msg = f'Error: {error_msg}'

#         return {
#             'success': False,
#             'has_image': False,
#             'error': msg,
#             'user_id': user_id
#         }
#  -------------------------------------------------------------------------------------------------------------------------------------
import os
import base64
import requests
import io
import json
import re
from groq import Groq
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from dotenv import load_dotenv

load_dotenv()

groq_client = Groq(api_key=os.getenv('GROQ_API_KEY'))
HF_API_KEY  = os.getenv('HF_API_KEY')
HF_API_URL  = "https://router.huggingface.co/hf-inference/models/stabilityai/stable-diffusion-xl-base-1.0"

FONTS_DIR    = os.path.join(os.path.dirname(__file__), 'fonts')
FONT_BOLD    = os.path.join(FONTS_DIR, 'Roboto-Bold.ttf')
FONT_REGULAR = os.path.join(FONTS_DIR, 'Roboto-Regular.ttf')
FONT_BLACK   = os.path.join(FONTS_DIR, 'Roboto-Black.ttf')   # download Roboto Black for extra punch

THUMB_W = 1280
THUMB_H = 720


# ═══════════════════════════════════════════════════════════════════════════════
# STEP 1 — Groq vision: analyse ALL images + prompt → rich design JSON
# ═══════════════════════════════════════════════════════════════════════════════

def _analyse_with_groq(prompt: str, images: list) -> dict:
    content = []

    for i, img_file in enumerate(images):
        img_file.seek(0)
        img_bytes = img_file.read()
        pil = Image.open(io.BytesIO(img_bytes))
        pil.thumbnail((768, 768))           # higher res for better analysis
        buf = io.BytesIO()
        pil.save(buf, format='JPEG', quality=85)
        b64 = base64.b64encode(buf.getvalue()).decode()
        content.append({
            "type": "image_url",
            "image_url": {"url": f"data:image/jpeg;base64,{b64}"}
        })

    image_count = len(images)

    content.append({
        "type": "text",
        "text": f"""You are a world-class YouTube thumbnail designer who creates viral thumbnails.

The user uploaded {image_count} image(s):
- Image 1: The main person/subject (their face photo for the thumbnail)
- Image 2+ (if any): Reference thumbnails, logos, products, or style inspiration

Analyse the person's appearance, expressions, and all reference images carefully.

Based on the user prompt and all images, return ONLY this exact JSON (no markdown, no explanation):

{{
  "bg_prompt": "extremely detailed photorealistic Stable Diffusion prompt for background — include specific relevant props (laptop with VS Code, gym equipment, cooking ingredients, etc.), professional studio lighting, bokeh depth of field, cinematic quality — NO people, NO faces, NO text, NO watermarks — 8k ultra HD",
  "negative_bg_prompt": "people, faces, person, human, text, watermark, low quality, blurry, nsfw",
  "title_line1": "FIRST LINE max 3 words ALL CAPS",
  "title_line2": "SECOND LINE max 3 words ALL CAPS",
  "subtitle": "supporting tagline max 5 words",
  "title_color1": "#FFFFFF",
  "title_color2": "#FFD700",
  "accent_color": "#hex color matching the topic perfectly",
  "bg_overlay_opacity": 0.55,
  "style": "one of: tech, nature, gaming, education, business, dramatic, fitness, cooking, travel, finance",
  "layout": "one of: face-left, face-right",
  "text_shadow_color": "#000000",
  "badge_text": "max 2 words for top badge e.g. TUTORIAL, FREE COURSE, MUST WATCH",
  "badge_color": "#hex",
  "show_glow": true,
  "glow_color": "#FFFFFF",
  "person_scale": 1.05,
  "decoration": "one of: code-snippets, sparkles, arrows, none, fire, stars, tech-icons, lightning"
}}

Rules:
- bg_prompt MUST mention specific props related to the topic
- title_line1 and title_line2 together form the main title
- accent_color must match topic: education=blue, gaming=purple, fitness=orange, cooking=green, finance=gold
- decoration adds floating elements around the person to make it dynamic
- show_glow adds a white outline around the person to make them pop
- person_scale between 0.9 and 1.15

User prompt: {prompt}"""
    })

    response = groq_client.chat.completions.create(
        model="meta-llama/llama-4-scout-17b-16e-instruct",
        messages=[{"role": "user", "content": content}],
        max_tokens=600,
        temperature=0.2
    )

    raw = response.choices[0].message.content.strip()
    raw = re.sub(r'```json|```', '', raw).strip()
    match = re.search(r'\{.*\}', raw, re.DOTALL)
    if match:
        try:
            return json.loads(match.group())
        except Exception as e:
            print(f"JSON parse error: {e}\nRaw: {raw[:300]}")

    # Fallback defaults
    return {
        "bg_prompt": f"professional cinematic background for {prompt}, studio lighting, bokeh, 8k",
        "negative_bg_prompt": "people, faces, text, watermark, low quality",
        "title_line1": prompt.split()[:3].__class__.__name__ and ' '.join(prompt.upper().split()[:3]),
        "title_line2": ' '.join(prompt.upper().split()[3:6]) or "TUTORIAL",
        "subtitle": "Learn from the Best",
        "title_color1": "#FFFFFF",
        "title_color2": "#FFD700",
        "accent_color": "#6C63FF",
        "bg_overlay_opacity": 0.55,
        "style": "education",
        "layout": "face-left",
        "text_shadow_color": "#000000",
        "badge_text": "TUTORIAL",
        "badge_color": "#6C63FF",
        "show_glow": True,
        "glow_color": "#FFFFFF",
        "person_scale": 1.0,
        "decoration": "none"
    }


# ═══════════════════════════════════════════════════════════════════════════════
# STEP 2 — Hugging Face SDXL: generate background image
# ═══════════════════════════════════════════════════════════════════════════════

def _generate_background(design: dict) -> Image.Image | None:
    style = design.get('style', 'education')
    bg_prompt = design.get('bg_prompt', '')
    neg_prompt = design.get('negative_bg_prompt', 'people, faces, text, watermark, blurry')

    style_boosters = {
        "tech":      "dark futuristic tech environment, glowing blue circuits, holographic displays, ",
        "education": "clean modern study desk, warm professional lighting, books and stationery, ",
        "gaming":    "epic gaming setup, RGB neon lighting, multiple monitors, dark room, ",
        "nature":    "lush vibrant nature, golden hour light, soft bokeh, serene, ",
        "business":  "sleek modern office, floor-to-ceiling glass, city skyline view, ",
        "dramatic":  "cinematic moody scene, dramatic shadows, god rays, atmospheric fog, ",
        "fitness":   "modern gym interior, equipment, motivational lighting, energetic, ",
        "cooking":   "beautiful kitchen setup, ingredients, warm lighting, professional, ",
        "travel":    "stunning travel destination, golden hour, vibrant colors, wide angle, ",
        "finance":   "financial trading desk, multiple screens, charts, professional, ",
    }

    booster = style_boosters.get(style, "professional clean background, ")
    full_prompt = (
        booster + bg_prompt +
        ", ultra high quality, 8k, photorealistic, cinematic lighting, "
        "professional photography, no people, no faces, no text"
    )

    headers = {"Authorization": f"Bearer {HF_API_KEY}"}
    payload = {
        "inputs": full_prompt,
        "parameters": {
            "width": THUMB_W,
            "height": THUMB_H,
            "num_inference_steps": 20,
            "guidance_scale": 8.0,
            "negative_prompt": neg_prompt + ", cartoon, anime, painting, ugly, deformed"
        }
    }

    print(f"[BG] Generating: {full_prompt[:120]}...")
    response = requests.post(HF_API_URL, headers=headers, json=payload, timeout=240)

    if response.status_code == 200:
        img = Image.open(io.BytesIO(response.content)).convert("RGBA")
        print("[BG] Background generated successfully")
        return img
    else:
        print(f"[BG] HF error {response.status_code}: {response.text[:200]}")
        return None


# ═══════════════════════════════════════════════════════════════════════════════
# STEP 3 — rembg: remove background from face photo
# ═══════════════════════════════════════════════════════════════════════════════

def _remove_bg(image_file) -> Image.Image | None:
    """
    Try rembg first. If it crashes (out of memory on free hosting),
    fall back to a lightweight edge-based crop.
    """
    try:
        from rembg import remove
        image_file.seek(0)
        img_bytes = image_file.read()

        # Check available memory before running rembg
        import psutil
        available_mb = psutil.virtual_memory().available / 1024 / 1024
        print(f"[FACE] Available memory: {available_mb:.0f}MB")

        if available_mb < 400:
            print("[FACE] Low memory — skipping rembg, using fallback")
            return _remove_bg_fallback(image_file)

        result_bytes = remove(img_bytes)
        result = Image.open(io.BytesIO(result_bytes)).convert("RGBA")
        print(f"[FACE] rembg success: {result.size}")
        return result

    except Exception as e:
        print(f"[FACE] rembg failed: {e} — using fallback")
        image_file.seek(0)
        return _remove_bg_fallback(image_file)


def _remove_bg_fallback(image_file) -> Image.Image | None:
    """
    Lightweight fallback — no AI needed.
    Crops person from center-bottom of image.
    Works well for portrait/selfie photos.
    """
    try:
        image_file.seek(0)
        img = Image.open(io.BytesIO(image_file.read())).convert("RGBA")

        w, h = img.size

        # Crop to portrait ratio focusing on person
        # Take center 70% width, full height
        left   = int(w * 0.15)
        right  = int(w * 0.85)
        top    = 0
        bottom = h
        img = img.crop((left, top, right, bottom))

        # Create soft edge transparency on left and right sides
        # So person blends into background naturally
        data = img.load()
        w2, h2 = img.size
        fade_width = int(w2 * 0.08)  # 8% fade on each side

        for y in range(h2):
            for x in range(fade_width):
                # Left fade
                alpha = int(255 * (x / fade_width))
                r, g, b, a = data[x, y]
                data[x, y] = (r, g, b, min(a, alpha))

                # Right fade
                rx = w2 - 1 - x
                r, g, b, a = data[rx, y]
                data[rx, y] = (r, g, b, min(a, alpha))

        print(f"[FACE] Fallback crop success: {img.size}")
        return img

    except Exception as e:
        print(f"[FACE] Fallback also failed: {e}")
        return None

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

def _hex_to_rgb(h: str) -> tuple:
    h = h.lstrip('#')
    if len(h) == 3:
        h = ''.join(c*2 for c in h)
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def _load_fonts(font_size: int):
    try:
        bold_path = FONT_BLACK if os.path.exists(FONT_BLACK) else FONT_BOLD
        return {
            'title':    ImageFont.truetype(bold_path, font_size),
            'subtitle': ImageFont.truetype(FONT_REGULAR, 44),
            'badge':    ImageFont.truetype(FONT_BOLD, 32),
            'deco':     ImageFont.truetype(FONT_BOLD, 36),
        }
    except Exception:
        default = ImageFont.load_default()
        return {'title': default, 'subtitle': default, 'badge': default, 'deco': default}


def _fit_text_to_width(draw, text, font_path, max_width, start_size=110, min_size=48):
    """Reduce font size until text fits within max_width pixels."""
    size = start_size
    while size >= min_size:
        try:
            font = ImageFont.truetype(font_path, size)
        except Exception:
            font = ImageFont.load_default()
            return font, size
        bbox = draw.textbbox((0, 0), text, font=font)
        if (bbox[2] - bbox[0]) <= max_width:
            return font, size
        size -= 4
    try:
        return ImageFont.truetype(font_path, min_size), min_size
    except Exception:
        return ImageFont.load_default(), min_size


def _draw_text_with_shadow(draw, pos, text, font, fill, shadow_color, shadow_offset=4):
    x, y = pos
    # Multi-direction shadow for depth
    for dx, dy in [(shadow_offset, shadow_offset), (-1, shadow_offset), (shadow_offset, -1)]:
        draw.text((x + dx, y + dy), text, font=font, fill=shadow_color)
    draw.text((x, y), text, font=font, fill=fill)

def _draw_topic_logos(canvas, design, layout):
    """Draw vector-style topic logos based on style."""
    style = design.get('style', 'education')
    decoration = design.get('decoration', 'none')
    accent = _hex_to_rgb(design.get('accent_color', '#6C63FF'))

    # Only draw logos if decoration mentions tech-icons or topic logos
    if 'logo' not in design.get('decoration', '') and \
       'icon' not in design.get('decoration', ''):
        return canvas

    deco = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(deco)

    # Position logos on opposite side of person
    if layout == 'face-left':
        lx, ly = THUMB_W - 280, 200
    else:
        lx, ly = 80, 200

    r, g, b = accent

    if style == 'tech' or 'flutter' in str(design).lower():
        # Flutter-style diamond logo
        cx, cy = lx + 60, ly + 60
        size = 55
        # Outer diamond — blue
        draw.polygon([
            (cx, cy - size), (cx + size, cy),
            (cx, cy + size), (cx - size, cy)
        ], fill=(r, g, b, 220))
        # Inner diamond — white cutout
        draw.polygon([
            (cx, cy - size//2), (cx + size//2, cy),
            (cx, cy + size), (cx - size//2, cy)
        ], fill=(max(r-40,0), max(g-40,0), min(b+20,255), 220))

        # Dart-style hexagon
        import math
        cx2, cy2 = lx + 60, ly + 160
        r2 = 40
        pts = []
        for k in range(6):
            angle = math.pi * k / 3 - math.pi / 6
            pts.append((cx2 + r2 * math.cos(angle),
                        cy2 + r2 * math.sin(angle)))
        draw.polygon(pts, fill=(0, 180, 200, 200))
        draw.polygon(pts, outline=(255, 255, 255, 100), width=2)

    elif style == 'gaming':
        # Gamepad icon shape
        cx, cy = lx + 60, ly + 60
        draw.rounded_rectangle(
            [(cx-50, cy-30), (cx+50, cy+30)],
            radius=20, fill=(r, g, b, 200))
        draw.ellipse([(cx+20, cy-10), (cx+40, cy+10)],
                     fill=(255,255,255,180))
        draw.line([(cx-35, cy), (cx-15, cy)], fill=(255,255,255,180), width=4)
        draw.line([(cx-25, cy-10), (cx-25, cy+10)], fill=(255,255,255,180), width=4)

    return Image.alpha_composite(canvas.convert("RGBA"), deco)
# ═══════════════════════════════════════════════════════════════════════════════
# STEP 4 — Composite: layer everything into final thumbnail
# ═══════════════════════════════════════════════════════════════════════════════

def _composite(background: Image.Image, face_img: Image.Image | None,
               reference_imgs: list, design: dict) -> Image.Image:

    layout        = design.get('layout', 'face-left')
    show_glow     = design.get('show_glow', True)
    glow_color    = _hex_to_rgb(design.get('glow_color', '#FFFFFF'))
    accent_color  = _hex_to_rgb(design.get('accent_color', '#6C63FF'))
    overlay_alpha = float(design.get('bg_overlay_opacity', 0.55))
    decoration    = design.get('decoration', 'none')
    person_scale  = float(design.get('person_scale', 1.0))
    person_scale  = max(0.85, min(1.15, person_scale))   # clamp safely

    # ── 1. Background ──────────────────────────────────────────────────────────
    canvas = background.copy().resize((THUMB_W, THUMB_H), Image.LANCZOS).convert("RGBA")

    # ── 2. Directional dark gradient overlay ───────────────────────────────────
    overlay = Image.new("RGBA", (THUMB_W, THUMB_H), (0, 0, 0, 0))
    draw_ov = ImageDraw.Draw(overlay)
    max_alpha = int(255 * overlay_alpha)

    if layout == 'face-left':
        # Person left → darken right side for text
        text_zone_start = THUMB_W // 2
        for i in range(text_zone_start, THUMB_W):
            a = int(max_alpha * (i - text_zone_start) / (THUMB_W - text_zone_start))
            draw_ov.line([(i, 0), (i, THUMB_H)], fill=(0, 0, 0, a))
        # Light darken on far left for depth
        for i in range(180):
            a = int(80 * (1 - i / 180))
            draw_ov.line([(i, 0), (i, THUMB_H)], fill=(0, 0, 0, a))
    else:
        # Person right → darken left side for text
        for i in range(THUMB_W // 2):
            a = int(max_alpha * (1 - i / (THUMB_W // 2)))
            draw_ov.line([(i, 0), (i, THUMB_H)], fill=(0, 0, 0, a))
        for i in range(THUMB_W - 180, THUMB_W):
            a = int(80 * (i - (THUMB_W - 180)) / 180)
            draw_ov.line([(i, 0), (i, THUMB_H)], fill=(0, 0, 0, a))

    canvas = Image.alpha_composite(canvas, overlay)

    # ── 3. Accent color strip at bottom ───────────────────────────────────────
    strip = Image.new("RGBA", (THUMB_W, THUMB_H), (0, 0, 0, 0))
    draw_strip = ImageDraw.Draw(strip)
    draw_strip.rectangle(
        [(0, THUMB_H - 8), (THUMB_W, THUMB_H)],
        fill=(*accent_color, 255)
    )
    canvas = Image.alpha_composite(canvas, strip)

    # ── 4. Person with glow ───────────────────────────────────────────────────
    if face_img:
        face = face_img.convert("RGBA")
        # Increase default scale
        face_h = int(THUMB_H * min(person_scale * 1.08, 1.15))
        face_ratio = face.width / face.height
        face_w = int(face_h * face_ratio)
        face = face.resize((face_w, face_h), Image.LANCZOS)

        if layout == 'face-left':
            face_x = 10
        else:
            face_x = THUMB_W - face_w - 10

        # Push person UP by 40px so more of body shows
        face_y = THUMB_H - face_h - 40    # ← was 0, now -40

        if show_glow:
            # White glow outline — expand alpha mask and fill white
            glow_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
            temp = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
            temp.paste(face, (face_x, face_y), face)

            r, g, b, a = temp.split()
            # Expand mask for glow thickness
            a_glow = a.filter(ImageFilter.MaxFilter(15))
            a_glow = a_glow.filter(ImageFilter.GaussianBlur(3))

            white_fill = Image.new("RGBA", canvas.size,
                                   (*glow_color, 220))
            white_fill.putalpha(a_glow)
            canvas = Image.alpha_composite(canvas, white_fill)

        # Paste actual face on top of glow
        canvas.paste(face, (face_x, face_y), face)

    # ── 5. Decorative elements ────────────────────────────────────────────────
    canvas = _draw_decorations(canvas, decoration, accent_color, layout)

    # ── 6. Reference image inset (bottom corner opposite to person) ───────────
    if reference_imgs:
        try:
            ref = reference_imgs[0].convert("RGBA")
            ref_w, ref_h = 280, 175
            ref = ref.resize((ref_w, ref_h), Image.LANCZOS)
            # Place on opposite side of person
            if layout == 'face-left':
                ref_x = THUMB_W - ref_w - 30
            else:
                ref_x = 30
            ref_y = THUMB_H - ref_h - 30

            # Rounded mask for ref image
            mask = Image.new("L", (ref_w, ref_h), 0)
            mask_draw = ImageDraw.Draw(mask)
            mask_draw.rounded_rectangle([(0, 0), (ref_w, ref_h)],
                                         radius=16, fill=255)
            ref.putalpha(mask)

            # Subtle border around ref image
            border_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
            bd = ImageDraw.Draw(border_layer)
            bd.rounded_rectangle(
                [ref_x - 3, ref_y - 3, ref_x + ref_w + 3, ref_y + ref_h + 3],
                radius=18, fill=(*accent_color, 180)
            )
            canvas = Image.alpha_composite(canvas, border_layer)
            canvas.paste(ref, (ref_x, ref_y), ref)
        except Exception as e:
            print(f"[REF] Reference image failed: {e}")

    # ── 7. Draw all text ───────────────────────────────────────────────────────
    canvas = canvas.convert("RGB")
    draw = ImageDraw.Draw(canvas)

    title_line1   = design.get('title_line1', 'YOUR').upper()
    title_line2   = design.get('title_line2', 'TITLE').upper()
    subtitle      = design.get('subtitle', '')
    color1        = _hex_to_rgb(design.get('title_color1', '#FFFFFF'))
    color2        = _hex_to_rgb(design.get('title_color2', '#FFD700'))
    shadow_color  = _hex_to_rgb(design.get('text_shadow_color', '#000000'))

    base_font_size = 110
    fonts = _load_fonts(base_font_size)

    # Text X position based on layout
    if layout == 'face-left':
        text_x = THUMB_W // 2 + 30
        max_w = THUMB_W // 2 - 60
    else:
        text_x = 60
        max_w = THUMB_W // 2 - 60

    # ── Text zone width — NEVER overflow this ────────────────────────────────
    # Leave 40px breathing room from right edge of text zone
    safe_text_w = max_w - 40

    bold_path = FONT_BLACK if os.path.exists(FONT_BLACK) else FONT_BOLD

    # Auto-fit both lines independently
    font_l1, size_l1 = _fit_text_to_width(draw, title_line1, bold_path, safe_text_w)
    font_l2, size_l2 = _fit_text_to_width(draw, title_line2, bold_path, safe_text_w)

    # Use the smaller of the two sizes for visual consistency
    final_size = min(size_l1, size_l2)
    try:
        font_title_final = ImageFont.truetype(bold_path, final_size)
    except Exception:
        font_title_final = ImageFont.load_default()

    fonts['title'] = font_title_final
    line_gap = 20
    line_h = final_size + line_gap
    total_text_h = line_h * 2 + 60 + (54 if subtitle else 0)
    start_y = (THUMB_H - total_text_h) // 2

    # Accent vertical bar
    bar_h = line_h * 2 + 20
    bar_x = text_x - 20
    draw.rectangle(
        [bar_x, start_y - 10, bar_x + 10, start_y + bar_h],
        fill=accent_color
    )


    # Title line 1 — WHITE
    _draw_text_with_shadow(
        draw, (text_x, start_y),
        title_line1, font_title_final,
        fill=(255, 255, 255),
        shadow_color=(0, 0, 0), shadow_offset=5
    )

    # Title line 2 — ACCENT COLOR (blue/yellow etc from design)
    _draw_text_with_shadow(
        draw, (text_x, start_y + line_h),
        title_line2, font_title_final,
        fill=accent_color,
        shadow_color=(0, 0, 0), shadow_offset=5
    )

    # Subtitle — safely below title with gap
    if subtitle:
        sub_y = start_y + line_h * 2 + 28
        # Make sure subtitle also fits
        font_sub, _ = _fit_text_to_width(
            draw, subtitle, FONT_REGULAR, safe_text_w, start_size=46, min_size=28)
        draw.text((text_x, sub_y), subtitle,
                  font=font_sub, fill=(*accent_color,))
    
    # ── 8. Badge top corner ───────────────────────────────────────────────────
    badge_text  = design.get('badge_text', 'TUTORIAL').upper()
    badge_color = _hex_to_rgb(design.get('badge_color', '#6C63FF'))
    badge_x     = text_x
    badge_y     = 40
    bbox = draw.textbbox((0, 0), badge_text, font=fonts['badge'])
    pad  = 18
    bw   = bbox[2] + pad * 2
    bh   = bbox[3] + pad

    draw.rounded_rectangle(
        [badge_x, badge_y, badge_x + bw, badge_y + bh],
        radius=10, fill=badge_color
    )
    draw.text((badge_x + pad, badge_y + pad // 2),
              badge_text, font=fonts['badge'], fill=(255, 255, 255))

    print(f"[COMPOSITE] Done — layout={layout} title='{title_line1} / {title_line2}'")
    # Draw topic logos dynamically
    canvas_rgba = _draw_topic_logos(canvas.convert("RGBA"), design, layout)
    canvas = canvas_rgba.convert("RGB")

    return canvas

    
# ═══════════════════════════════════════════════════════════════════════════════
# DECORATIONS — dynamic floating elements around person
# ═══════════════════════════════════════════════════════════════════════════════

def _draw_decorations(canvas: Image.Image, decoration: str,
                      accent_color: tuple, layout: str) -> Image.Image:
    if decoration == 'none':
        return canvas

    deco_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(deco_layer)

    # Person is on left → decorations on left side, else right
    base_x = 80 if layout == 'face-left' else THUMB_W - 200

    r, g, b = accent_color

    if decoration == 'sparkles':
        positions = [
            (base_x + 120, 80),  (base_x + 300, 160),
            (base_x + 60,  260), (base_x + 280, 340),
            (base_x + 150, 420),
        ]
        sizes = [18, 12, 20, 14, 16]
        for (x, y), s in zip(positions, sizes):
            # Draw 4-point star
            draw.polygon([(x, y-s), (x+4, y-4), (x+s, y),
                          (x+4, y+4), (x, y+s), (x-4, y+4),
                          (x-s, y),  (x-4, y-4)],
                         fill=(r, g, b, 180))

    elif decoration == 'arrows':
        arrow_positions = [(base_x + 200, 200), (base_x + 220, 260), (base_x + 200, 320)]
        for (x, y) in arrow_positions:
            draw.polygon([(x, y), (x+40, y+20), (x, y+40)],
                         fill=(r, g, b, 160))

    elif decoration == 'fire':
        positions = [(base_x + 100, 500), (base_x + 160, 480), (base_x + 220, 510)]
        for (x, y) in positions:
            draw.ellipse([(x-12, y-30), (x+12, y+10)], fill=(255, 100, 0, 140))
            draw.ellipse([(x-8,  y-20), (x+8,  y+8)],  fill=(255, 200, 0, 160))

    elif decoration == 'stars':
        import math
        star_positions = [
            (base_x + 80, 100), (base_x + 260, 80),
            (base_x + 40, 300), (base_x + 300, 400),
        ]
        for (cx, cy) in star_positions:
            pts = []
            for k in range(10):
                angle = math.pi * k / 5 - math.pi / 2
                radius = 20 if k % 2 == 0 else 9
                pts.append((cx + radius * math.cos(angle),
                             cy + radius * math.sin(angle)))
            draw.polygon(pts, fill=(255, 220, 0, 200))

    elif decoration == 'lightning':
        lx = base_x + 180
        draw.polygon(
            [(lx, 80), (lx-20, 200), (lx+10, 200), (lx-10, 360), (lx+30, 200), (lx, 200)],
            fill=(r, g, b, 200)
        )

    elif decoration == 'code-snippets':
        try:
            font = ImageFont.truetype(FONT_BOLD, 22)
        except Exception:
            font = ImageFont.load_default()
        snippets = ['{ }', '</>', '( )', '=>', '[];', '##']
        positions = [
            (base_x + 20, 80),  (base_x + 180, 120),
            (base_x + 60, 220), (base_x + 220, 300),
            (base_x + 40, 400), (base_x + 200, 460),
        ]
        for text, (x, y) in zip(snippets, positions):
            draw.text((x, y), text, font=font, fill=(r, g, b, 100))

    elif decoration == 'tech-icons':
        # Draw simple geometric tech shapes
        positions = [(base_x + 100, 120), (base_x + 220, 200), (base_x + 80, 350)]
        for (x, y) in positions:
            draw.rounded_rectangle([(x, y), (x+50, y+50)],
                                    radius=8, outline=(r, g, b, 120), width=3)
            draw.line([(x+10, y+25), (x+40, y+25)], fill=(r, g, b, 120), width=2)
            draw.line([(x+25, y+10), (x+25, y+40)], fill=(r, g, b, 120), width=2)

    return Image.alpha_composite(canvas, deco_layer)


# ═══════════════════════════════════════════════════════════════════════════════
# MAIN ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════════

def generate_thumbnail(prompt: str, images: list, user_id: str) -> dict:
    all_images = list(images)
    print(f"\n{'='*60}")
    print(f"[START] Generating thumbnail for: '{prompt}'")
    print(f"[START] Images received: {len(all_images)}")

    # ── Rewind all files ──────────────────────────────────────────────────────
    for f in all_images:
        f.seek(0)

    # ── Step 1: Groq analyses ALL images + prompt ─────────────────────────────
    print("[1/4] Analysing with Groq vision...")
    design = _analyse_with_groq(prompt, all_images)
    print(f"[1/4] Design: layout={design.get('layout')}, "
          f"style={design.get('style')}, "
          f"deco={design.get('decoration')}, "
          f"title='{design.get('title_line1')} / {design.get('title_line2')}'")

    # ── Step 2: Rewind + process each image ───────────────────────────────────
    for f in all_images:
        f.seek(0)

    face_img       = None
    reference_imgs = []

    for i, img_file in enumerate(all_images):
        img_file.seek(0)
        if i == 0:
            print("[2/4] Removing background from face photo...")
            face_img = _remove_bg(img_file)
        else:
            img_file.seek(0)
            try:
                ref = Image.open(io.BytesIO(img_file.read())).convert("RGBA")
                reference_imgs.append(ref)
                print(f"[2/4] Reference image {i} loaded: {ref.size}")
            except Exception as e:
                print(f"[2/4] Reference image {i} failed: {e}")

    # ── Step 3: Generate background ───────────────────────────────────────────
    print("[3/4] Generating background with SDXL...")
    bg = _generate_background(design)

    if bg is None:
        print("[3/4] Background generation failed — model warming up")
        return {
            'success': True,
            'has_image': False,
            'description': (
                f"Title: {design.get('title_line1')} {design.get('title_line2')} | "
                f"Style: {design.get('style')}"
            ),
            'user_id': user_id,
            'message': 'AI model is warming up. Please try again in 30 seconds.'
        }

    # ── Step 4: Composite ─────────────────────────────────────────────────────
    print("[4/4] Compositing all layers...")
    final = _composite(bg, face_img, reference_imgs, design)

    # ── Encode ────────────────────────────────────────────────────────────────
    buf = io.BytesIO()
    final.save(buf, format='PNG', optimize=True)
    b64 = base64.b64encode(buf.getvalue()).decode()

    print(f"[DONE] Thumbnail generated successfully — {len(b64)//1024}KB")
    print('='*60)

    return {
        'success': True,
        'has_image': True,
        'image_base64': b64,
        'description': (
            f"Title: {design.get('title_line1')} {design.get('title_line2')} | "
            f"Style: {design.get('style')} | "
            f"Layout: {design.get('layout')} | "
            f"Decoration: {design.get('decoration')}"
        ),
        'design': design,    # send full design to Flutter for debugging
        'user_id': user_id
    }
