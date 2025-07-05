# # # # Added turn off feature and updated wake phrases for iris and how are u also

from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime
import requests
from dotenv import load_dotenv
import os
import time
from functools import lru_cache

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter frontend

# WeatherAPI configuration
WEATHER_API_KEY = os.getenv('WEATHER_API_KEY')  # Loaded from .env file
WEATHER_API_URL = 'http://api.weatherapi.com/v1/current.json'

# Multiple geolocation APIs for redundancy
GEOLOCATION_APIS = [
    'http://ip-api.com/json/',  # 45 requests/minute
    'https://ipinfo.io/json',   # 1000 requests/month
    'https://ipapi.co/json/',   # 1000 requests/month
]

# Cache for storing location data to avoid repeated API calls
location_cache = {}
last_location_request = 0
LOCATION_CACHE_DURATION = 1800  # 30 minutes in seconds
api_index = 0  # Track which API to use next

# Assistant state tracking with enhanced sleep mode support
assistant_states = {}  # Track sleep state per client IP
last_activity = {}     # Track last activity time per client IP

def get_client_location():
    """Fetch the client's city using multiple geolocation APIs with rotation."""
    global last_location_request, api_index
    current_time = time.time()
    
    try:
        # Get client IP address from the request
        client_ip = request.remote_addr
        
        # For local development, skip localhost IPs
        if client_ip in ['127.0.0.1', 'localhost', '::1']:
            client_ip = 'auto'  # Let the API detect the real IP
        
        # Check if we have cached data for this IP
        cache_key = f"{client_ip}_location"
        if cache_key in location_cache:
            cached_data = location_cache[cache_key]
            if current_time - cached_data['timestamp'] < LOCATION_CACHE_DURATION:
                print(f"Using cached location: {cached_data['city']}")
                return cached_data['city']
        
        # Rate limiting: wait at least 1 second between requests
        if current_time - last_location_request < 1:
            time.sleep(1)
        
        # Try multiple APIs in rotation
        for attempt in range(len(GEOLOCATION_APIS)):
            api_url = GEOLOCATION_APIS[api_index % len(GEOLOCATION_APIS)]
            
            try:
                print(f"Trying geolocation API: {api_url}")
                
                headers = {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                    'Accept': 'application/json'
                }
                
                # Modify URL for specific IP if not localhost
                if client_ip != 'auto' and 'ip-api.com' in api_url:
                    api_url = f"http://ip-api.com/json/{client_ip}"
                elif client_ip != 'auto' and 'ipinfo.io' in api_url:
                    api_url = f"https://ipinfo.io/{client_ip}/json"
                
                response = requests.get(api_url, headers=headers, timeout=10)
                last_location_request = time.time()
                
                if response.status_code == 200:
                    geo_data = response.json()
                    
                    # Extract city based on API response format
                    city = None
                    if 'ip-api.com' in api_url:
                        city = geo_data.get('city')
                    elif 'ipinfo.io' in api_url:
                        city = geo_data.get('city')
                    elif 'ipapi.co' in api_url:
                        city = geo_data.get('city')
                    
                    if city and city.lower() not in ['unknown', '', 'none']:
                        # Cache the result
                        location_cache[cache_key] = {
                            'city': city,
                            'timestamp': current_time
                        }
                        
                        print(f"Successfully fetched location: {city}")
                        return city
                    else:
                        print(f"API returned invalid city: {city}")
                
                elif response.status_code == 429:
                    print(f"Rate limited on {api_url}, trying next API")
                else:
                    print(f"API {api_url} returned status code: {response.status_code}")
            
            except Exception as e:
                print(f"Error with API {api_url}: {e}")
            
            # Move to next API
            api_index += 1
        
        print("All geolocation APIs failed or returned invalid data")
        return None
    
    except Exception as e:
        print(f'Geolocation error: {e}')
        return None

@lru_cache(maxsize=20)
def get_weather_cached(location, cache_key):
    """Get weather data with caching to avoid repeated API calls."""
    try:
        print(f"Fetching weather for: {location}")
        response = requests.get(
            WEATHER_API_URL,
            params={'key': WEATHER_API_KEY, 'q': location, 'aqi': 'no'},
            timeout=10
        )
        if response.status_code == 200:
            return response.json()
        else:
            print(f'Weather API error: Status code {response.status_code}')
            return None
    except Exception as e:
        print(f'Weather API error: {e}')
        return None

def update_client_activity(client_ip):
    """Update the last activity time for a client."""
    last_activity[client_ip] = time.time()

def is_valid_wake_phrase(message):
    """Check if the message contains valid wake phrases for iris."""
    wake_phrases = [
        'hey iris', 'hello iris', 'hi iris',
        'hey iris', 'hello iris', 'hi iris'  # Alternative spellings
    ]
    return any(phrase in message for phrase in wake_phrases)

@app.route('/voice', methods=['POST'])
def voice():
    data = request.get_json()
    # Get message and convert to lowercase for case-insensitive comparison
    message = data.get('message', '').lower().strip()
    
    # Get client IP to track assistant state
    client_ip = request.remote_addr
    update_client_activity(client_ip)
    
    print(f"Received message from {client_ip}: '{message}'")
    
    # Check for wake-up commands (these work even when assistant is in sleep mode)
    if is_valid_wake_phrase(message) and not assistant_states.get(client_ip, True):
        assistant_states[client_ip] = True  # Wake up assistant
        print(f"Assistant woken up for client {client_ip}")
        return jsonify({
            'response': 'Hi again! I was just resting. How can I help?',
            'assistant_active': True
        })
    
    # Check if assistant is active for this client
    if not assistant_states.get(client_ip, True):  # Default to True for new clients
        print(f"Assistant is sleeping for client {client_ip}, ignoring: '{message}'")
        # In sleep mode, only respond to wake phrases
        # Return a minimal response to avoid unnecessary TTS
        return jsonify({
            'response': '',  # Empty response to avoid speaking
            'assistant_active': False,
            'sleep_mode': True
        })
    
    # Check for sleep command
    if any(sleep_word in message for sleep_word in ['turn off', 'go to sleep', 'stop listening']):
        assistant_states[client_ip] = False  # Put assistant to sleep
        print(f"Assistant going to sleep for client {client_ip}")
        return jsonify({
            'response': 'Entering sleep mode. Say "Hey iris" or "Hello iris" to wake me up.',
            'assistant_active': False
        })
    
    # Check for time command
    if 'time' in message:
        # Fetch current system time and format it
        current_time = datetime.now().strftime('%I:%M %p')
        return jsonify({
            'response': f'The current time is {current_time}',
            'assistant_active': True
        })
    
    # Check for weather command
    if 'weather' in message:
        try:
            # Get client's location
            location = get_client_location()
            
            if not location:
                return jsonify({
                    'response': 'Sorry, I couldn\'t determine your location. Could you tell me which city you\'d like weather information for?',
                    'assistant_active': True
                })
            
            # Create cache key based on current hour to cache weather for 1 hour
            cache_key = f"{datetime.now().hour}_{location}"
            
            # Get weather data
            weather_data = get_weather_cached(location, cache_key)
            
            if weather_data:
                temp_c = weather_data['current']['temp_c']
                condition = weather_data['current']['condition']['text']
                location_name = weather_data['location']['name']
                return jsonify({
                    'response': f"It's currently {temp_c}°C with {condition.lower()} in {location_name}.",
                    'assistant_active': True
                })
            else:
                return jsonify({
                    'response': f'Sorry, I couldn\'t fetch weather data for {location}. Please try again later.',
                    'assistant_active': True
                })
        except Exception as e:
            print(f'Weather handling error: {e}')
            return jsonify({
                'response': "Sorry, I didn't catch that. You can ask me about the time, weather, say hello, or tell me to turn off!",
                'assistant_active': True
            })
    
    # Check for hello command
    if 'hello' in message:
        return jsonify({
            'response': 'Hello! How can I help you today?',
            'assistant_active': True
        })
    
    # Check for how are you command
    if 'how are you' in message:
        return jsonify({
            'response': "I'm doing well, thank you for asking! How can I assist you today?",
            'assistant_active': True
        })
    
    # Check for help command
    if any(help_word in message for help_word in ['what can you do', 'help', 'commands']):
        return jsonify({
            'response': "I can help you with the current time, weather information for your location, and answer basic questions. Say 'turn off' to put me to sleep, or 'Hey iris' to wake me up!",
            'assistant_active': True
        })
    
    # Check for thank you command
    if 'thank you' in message:
        return jsonify({
            'response': "You're welcome! I'm here to help anytime.",
            'assistant_active': True
        })
    
    # Fallback response for unrecognized commands
    return jsonify({
        'response': "Sorry, I didn't catch that. You can ask me about the time, weather, say hello, or tell me to turn off!",
        'assistant_active': True
    })

@app.route('/set-location', methods=['POST'])
def set_location():
    """Allow manual location setting from the frontend."""
    data = request.get_json()
    location = data.get('location', '').strip()
    
    if not location:
        return jsonify({'error': 'Location is required'}), 400
    
    try:
        # Validate location by checking if weather API can find it
        response = requests.get(
            WEATHER_API_URL,
            params={'key': WEATHER_API_KEY, 'q': location, 'aqi': 'no'},
            timeout=10
        )
        
        if response.status_code == 200:
            # Cache this location for the client IP
            client_ip = request.remote_addr
            cache_key = f"{client_ip}_location"
            location_cache[cache_key] = {
                'city': location,
                'timestamp': time.time()
            }
            return jsonify({'message': f'Location set to {location}', 'success': True})
        else:
            return jsonify({'error': 'Location not found'}), 400
        
    except Exception as e:
        print(f'Location validation error: {e}')
        return jsonify({'error': 'Error validating location'}), 500

@app.route('/assistant-status', methods=['GET'])
def get_assistant_status():
    """Get the current assistant status for the client."""
    client_ip = request.remote_addr
    is_active = assistant_states.get(client_ip, True)  # Default to True for new clients
    last_seen = last_activity.get(client_ip, 0)
    
    return jsonify({
        'assistant_active': is_active,
        'status': 'active' if is_active else 'sleeping',
        'last_activity': last_seen,
        'client_ip': client_ip  # For debugging
    })

@app.route('/wake-assistant', methods=['POST'])
def wake_assistant():
    """Manually wake up the assistant (useful for testing)."""
    client_ip = request.remote_addr
    assistant_states[client_ip] = True
    update_client_activity(client_ip)
    
    return jsonify({
        'message': 'Assistant has been woken up',
        'assistant_active': True
    })

@app.route('/sleep-assistant', methods=['POST'])
def sleep_assistant():
    """Manually put the assistant to sleep (useful for testing)."""
    client_ip = request.remote_addr
    assistant_states[client_ip] = False
    update_client_activity(client_ip)
    
    return jsonify({
        'message': 'Assistant has been put to sleep',
        'assistant_active': False
    })

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint with enhanced information."""
    active_clients = sum(1 for state in assistant_states.values() if state)
    sleeping_clients = sum(1 for state in assistant_states.values() if not state)
    
    return jsonify({
        'status': 'healthy', 
        'timestamp': datetime.now().isoformat(),
        'weather_api_configured': bool(WEATHER_API_KEY),
        'total_clients': len(assistant_states),
        'active_clients': active_clients,
        'sleeping_clients': sleeping_clients,
        'geolocation_apis': len(GEOLOCATION_APIS)
    })

if __name__ == '__main__':
    print("Starting iris Voice Assistant Backend...")
    print(f"Weather API Key loaded: {'Yes' if WEATHER_API_KEY else 'No'}")
    print(f"Available geolocation APIs: {len(GEOLOCATION_APIS)}")
    print("Wake phrases: 'Hey iris', 'Hello iris'")
    app.run(host='0.0.0.0', port=5000, debug=True)