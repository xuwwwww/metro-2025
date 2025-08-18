# pip install requests
import requests
import json

ENDPOINT = "https://c94vibu77k.execute-api.us-east-1.amazonaws.com/default/Metro-user-behavior-analysis-bedrock"

def call_api(prompt: str):
    payload = {"prompt": prompt}
    resp = requests.post(
        ENDPOINT,
        headers={"Content-Type": "application/json"},
        json=payload,
        timeout=30
    )
    print("Status code:", resp.status_code)
    try:
        data = resp.json()
        print("Response JSON:", json.dumps(data, ensure_ascii=False, indent=2))
    except ValueError:
        print("Raw response:", resp.text)

if __name__ == "__main__":
    call_api("Hello from local test")
