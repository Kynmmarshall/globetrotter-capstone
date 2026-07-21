"""
app/itineraries.py

Create and list itineraries for the authenticated user.

Routes
------
POST /itineraries – create a new itinerary
GET  /itineraries – list all itineraries for the logged-in user

Both routes require a valid JWT in the Authorization header.
"""
import uuid
import datetime

from flask import Blueprint, request, jsonify

from app.auth import get_current_user
from app.models import get_itineraries_for_user, save_itinerary

itineraries_bp = Blueprint("itineraries", __name__)


@itineraries_bp.route("/itineraries", methods=["POST"])
def create_itinerary():
    """Create a new itinerary for the authenticated user.

    Expected JSON body:
        {
          "title": "Summer in Europe",
          "destinations": ["Paris", "Rome"],
          "start_date": "2025-06-01",
          "end_date": "2025-06-15",
          "notes": "Optional free-text notes"
        }

    Returns 201 with the created itinerary on success.
    Requires: Authorization: ******
    """
    username = get_current_user(request)
    if not username:
        return jsonify({"error": "authentication required"}), 401

    data = request.get_json(silent=True) or {}
    title = data.get("title", "").strip()
    destinations = data.get("destinations", [])

    if not title:
        return jsonify({"error": "title is required"}), 400

    if not isinstance(destinations, list):
        return jsonify({"error": "destinations must be a list"}), 400

    itinerary = {
        "id": str(uuid.uuid4()),
        "username": username,
        "title": title,
        "destinations": destinations,
        "start_date": data.get("start_date", ""),
        "end_date": data.get("end_date", ""),
        "notes": data.get("notes", ""),
        "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }
    save_itinerary(itinerary)
    return jsonify(itinerary), 201


@itineraries_bp.route("/itineraries", methods=["GET"])
def list_itineraries():
    """List all itineraries for the authenticated user.

    Returns 200 with a JSON array of itinerary objects.
    Requires: Authorization: ******
    """
    username = get_current_user(request)
    if not username:
        return jsonify({"error": "authentication required"}), 401

    itineraries = get_itineraries_for_user(username)
    return jsonify(itineraries), 200
