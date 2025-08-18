# pip install requests
import json
import requests

ENDPOINT = "https://rd9nkhwh3g.execute-api.us-east-1.amazonaws.com/default/Metro-user-behavior-analysis"

def get_chatrooms():
    resp = requests.get(ENDPOINT, timeout=15)
    print("GET status:", resp.status_code)
    try:
        data = resp.json()
    except ValueError:
        print("Raw body:", resp.text)
        return None
    print(json.dumps(data, ensure_ascii=False, indent=2))
    return data



if __name__ == "__main__":
    # 測 GET（目前你的 Lambda 回傳 chatRooms IDs 應該會是這裡）
    get_chatrooms()
