import os, boto3

api_key = open('api.txt', 'r')

os.environ['AWS_BEARER_TOKEN_BEDROCK'] = api_key.read()
client = boto3.client("bedrock-runtime", region_name="us-east-1")

resp = client.converse(
    modelId="amazon.nova-lite-v1:0",
    messages=[{"role":"user","content":[{"text":"Hello"}]}],
)
print(resp)
