"""
app/__init__.py

Flask application factory.
"""
import os
from flask import Flask


def create_app():
    """Create and configure the Flask application."""
    app = Flask(__name__)

    # Secret key used for JWT signing.  Set the SECRET_KEY environment variable
    # in production.  The fallback is intentionally weak and must never be used
    # outside of local development.
    app.config["SECRET_KEY"] = os.environ.get(
        "SECRET_KEY", "globetrotter-secret-change-in-prod"
    )

    # Register all route blueprints
    from app.auth import auth_bp
    from app.destinations import destinations_bp
    from app.recommendations import recommendations_bp
    from app.itineraries import itineraries_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(destinations_bp)
    app.register_blueprint(recommendations_bp)
    app.register_blueprint(itineraries_bp)

    return app
