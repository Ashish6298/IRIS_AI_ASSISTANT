#added time, weather and thank u

from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime
import requests
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter frontend

# WeatherAPI configuration
WEATHER_API_KEY = os.getenv('WEATHER_API_KEY')  # Loaded from .env file
WEATHER_API_URL = 'http://api.weatherapi.com/v1/current.json'
GEOLOCATION_API_URL = 'https://ipapi.co/json/'  # Free geolocation API

def get_client_location():
    """Fetch the client's city based on their IP address."""
    try:
        # Get client IP address from the request
        client_ip = request.remote_addr
        # Make request to ipapi.co for geolocation
        response = requests.get(GEOLOCATION_API_URL)
        if response.status_code == 200:
            geo_data = response.json()
            city = geo_data.get('city', 'Unknown')
            if city == 'Unknown':
                return None  # Handle case where city is not found
            return city
        else:
            print(f'Geolocation API error: Status code {response.status_code}')
            return None
    except Exception as e:
        print(f'Geolocation API error: {e}')
        return None

@app.route('/voice', methods=['POST'])
def voice():
    data = request.get_json()
    # Get message and convert to lowercase for case-insensitive comparison
    message = data.get('message', '').lower().strip()
    
    # Intent recognition based on keywords
    if 'hello iris' in message:
        return jsonify({'response': 'Hello! How can I help you today?'})
    elif 'time' in message:
        # Fetch current system time and format it
        current_time = datetime.now().strftime('%I:%M %p')  # e.g., 12:13 AM
        return jsonify({'response': f'The current time is {current_time}'})
    elif 'weather' in message:
        try:
            # Get client's location dynamically
            location = get_client_location()
            if not location:
                return jsonify({'response': 'Sorry, I couldn’t determine your location for the weather.'})

            # Make request to WeatherAPI
            response = requests.get(
                WEATHER_API_URL,
                params={'key': WEATHER_API_KEY, 'q': location, 'aqi': 'no'}
            )
            if response.status_code == 200:
                weather_data = response.json()
                temp_c = weather_data['current']['temp_c']
                condition = weather_data['current']['condition']['text']
                return jsonify({
                    'response': f"It's currently {temp_c}°C with {condition.lower()} in {location}."
                })
            else:
                return jsonify({'response': 'Sorry, I couldn’t fetch the weather data.'})
        except Exception as e:
            print(f'Weather API error: {e}')
            return jsonify({'response': 'Sorry, there was an error fetching the weather.'})
    elif 'thank you' in message:
        return jsonify({'response': "You're welcome! I'm here if you need more help."})
    else:
        return jsonify({'response': "Sorry, I didn't catch that."})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)