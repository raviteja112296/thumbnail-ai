from flask import Flask
from flask_cors import CORS
from dotenv import load_dotenv
load_dotenv()
def create_app():
    app = Flask(__name__)
    CORS(app)

    from app.thumbnail.routes import thumbnail_bp
    app.register_blueprint(thumbnail_bp, url_prefix='/api/thumbnail')

    @app.route('/health')
    def health():
        return {'status': 'ok', 'version': '1.0'}

    return app