from flask import Blueprint, request, jsonify
from app.thumbnail.service import generate_thumbnail

thumbnail_bp = Blueprint('thumbnail', __name__)

@thumbnail_bp.route('/generate', methods=['POST'])
def generate():
    try:
        prompt = request.form.get('prompt', '')
        images = request.files.getlist('images')
        user_id = request.form.get('user_id', '')

        if not prompt:
            return jsonify({'error': 'Prompt is required'}), 400

        result = generate_thumbnail(prompt, images, user_id)
        return jsonify(result), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500