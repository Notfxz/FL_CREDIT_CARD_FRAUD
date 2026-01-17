import json

# This mimics exactly what Flutter sends (A string that looks like JSON)
incoming_data = '{"features": [0.1, 0.2, 0.3]}' 

print(f"Current Type: {type(incoming_data)}")

# --- THE PROBLEM ---
try:
    print(incoming_data['features']) # This will cause your error!
except TypeError as e:
    print(f"FAILED: {e}")

# --- THE FIX (This is what you added to your API) ---
if isinstance(incoming_data, str):
    incoming_data = json.loads(incoming_data)

print(f"New Type: {type(incoming_data)}")
print(f"SUCCESS: Data is now {incoming_data['features']}")