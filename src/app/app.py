from flask import Flask, jsonify

def create_app():
    app = Flask(__name__)

    @app.get("/")
    def index():
        return "Hello from terraform-apache-project (Apache + mod_wsgi + Flask)!"

    @app.get("/health")
    def health():
        return jsonify(status="ok")

    return app


# Local dev convenience: `python src/app/app.py`
if __name__ == "__main__":
    create_app().run(host="0.0.0.0", port=5000)
